import { ArkImageGenProvider } from './ark-image-gen.provider';
import { ScenePortraitProviderNotConfiguredError } from './errors';

// Contract tests: fully mocked HTTP, never touches the real Ark API. These
// exist to catch a vendor field-name/shape change early — see
// docs/reference/testing.md.

// The real shape ArkImageGenProvider passes as fetch's second argument (see
// ark-image-gen.provider.ts) — narrower than the DOM `RequestInit` type,
// which would otherwise force awkward handling of header/body shapes this
// provider never actually sends.
interface FetchCallInit {
  method?: string;
  headers?: Record<string, string>;
  body?: string;
}

function jsonResponse(body: unknown, ok = true, status = 200) {
  return {
    ok,
    status,
    json: () => Promise.resolve(body),
    text: () => Promise.resolve(JSON.stringify(body)),
    headers: { get: () => 'image/png' },
  };
}

function bufferResponse(bytes: string, ok = true, status = 200) {
  return {
    ok,
    status,
    arrayBuffer: () => Promise.resolve(Buffer.from(bytes)),
    headers: { get: () => 'image/png' },
  };
}

describe('ArkImageGenProvider', () => {
  const originalFetch = global.fetch;
  const originalApiKey = process.env.ARK_API_KEY;
  const originalModel = process.env.ARK_IMAGE_MODEL_ID;
  const originalBaseUrl = process.env.ARK_BASE_URL;

  beforeEach(() => {
    process.env.ARK_API_KEY = 'test-key';
    process.env.ARK_IMAGE_MODEL_ID = 'doubao-seedream-test';
    process.env.ARK_BASE_URL = 'https://ark.test/api/v3';
  });

  afterEach(() => {
    global.fetch = originalFetch;
    if (originalApiKey === undefined) delete process.env.ARK_API_KEY;
    else process.env.ARK_API_KEY = originalApiKey;
    if (originalModel === undefined) delete process.env.ARK_IMAGE_MODEL_ID;
    else process.env.ARK_IMAGE_MODEL_ID = originalModel;
    if (originalBaseUrl === undefined) delete process.env.ARK_BASE_URL;
    else process.env.ARK_BASE_URL = originalBaseUrl;
  });

  it('throws ScenePortraitProviderNotConfiguredError when ARK_API_KEY is blank', async () => {
    delete process.env.ARK_API_KEY;
    const provider = new ArkImageGenProvider();

    await expect(
      provider.generateCandidates({
        referenceImageUrl: 'https://r2/main.jpg',
        sceneText: 'x',
        count: 1,
      }),
    ).rejects.toBeInstanceOf(ScenePortraitProviderNotConfiguredError);
  });

  it('calls the correct endpoint with the expected auth header, model id, prompt, and reference image', async () => {
    const fetchMock = jest
      .fn()
      .mockImplementation((url: string, init: FetchCallInit = {}) => {
        if (url.endsWith('/images/generations')) {
          expect(init.method).toBe('POST');
          expect(init.headers?.Authorization).toBe('Bearer test-key');
          if (typeof init.body !== 'string') {
            throw new Error('Expected a JSON string request body');
          }
          const body = JSON.parse(init.body) as {
            model: string;
            prompt: string;
            image: string;
          };
          expect(body.model).toBe('doubao-seedream-test');
          expect(body.image).toBe('https://r2/main.jpg');
          expect(typeof body.prompt).toBe('string');
          expect(body.prompt).toContain('sunlit windowsill');
          return Promise.resolve(
            jsonResponse({
              data: [{ url: 'https://vendor.example/img1.png' }],
            }),
          );
        }
        if (url === 'https://vendor.example/img1.png') {
          return Promise.resolve(bufferResponse('fake-png-bytes'));
        }
        throw new Error(`Unexpected fetch call: ${url}`);
      });
    global.fetch = fetchMock;

    const provider = new ArkImageGenProvider();
    const result = await provider.generateCandidates({
      referenceImageUrl: 'https://r2/main.jpg',
      sceneText: 'dozing on a sunlit windowsill',
      count: 1,
    });

    expect(fetchMock).toHaveBeenCalledWith(
      'https://ark.test/api/v3/images/generations',
      expect.anything(),
    );
    expect(result).toHaveLength(1);
  });

  it('issues one independent request per candidate (no assumed batch/n param)', async () => {
    let generationCalls = 0;
    global.fetch = jest.fn().mockImplementation((url: string) => {
      if (url.endsWith('/images/generations')) {
        generationCalls += 1;
        return Promise.resolve(
          jsonResponse({
            data: [{ url: `https://vendor.example/img${generationCalls}.png` }],
          }),
        );
      }
      return Promise.resolve(bufferResponse('fake-bytes'));
    }) as any;

    const provider = new ArkImageGenProvider();
    const result = await provider.generateCandidates({
      referenceImageUrl: 'https://r2/main.jpg',
      sceneText: 'x',
      count: 4,
    });

    expect(generationCalls).toBe(4);
    expect(result).toHaveLength(4);
  });

  it('throws with the response body when the generation call is a non-2xx', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValue(
        jsonResponse({ error: 'bad request' }, false, 400),
      ) as any;
    const provider = new ArkImageGenProvider();

    await expect(
      provider.generateCandidates({
        referenceImageUrl: 'https://r2/main.jpg',
        sceneText: 'x',
        count: 1,
      }),
    ).rejects.toThrow(/400/);
  });

  it('throws when the response has no data[0].url', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValue(jsonResponse({ data: [] })) as any;
    const provider = new ArkImageGenProvider();

    await expect(
      provider.generateCandidates({
        referenceImageUrl: 'https://r2/main.jpg',
        sceneText: 'x',
        count: 1,
      }),
    ).rejects.toThrow(/no url/);
  });

  it('throws when downloading the generated asset fails', async () => {
    global.fetch = jest.fn().mockImplementation((url: string) => {
      if (url.endsWith('/images/generations')) {
        return Promise.resolve(
          jsonResponse({ data: [{ url: 'https://vendor.example/img1.png' }] }),
        );
      }
      return Promise.resolve(bufferResponse('', false, 404));
    }) as any;
    const provider = new ArkImageGenProvider();

    await expect(
      provider.generateCandidates({
        referenceImageUrl: 'https://r2/main.jpg',
        sceneText: 'x',
        count: 1,
      }),
    ).rejects.toThrow(/Failed to download/);
  });

  it('returns a non-empty Buffer for each downloaded candidate', async () => {
    global.fetch = jest.fn().mockImplementation((url: string) => {
      if (url.endsWith('/images/generations')) {
        return Promise.resolve(
          jsonResponse({ data: [{ url: 'https://vendor.example/img1.png' }] }),
        );
      }
      return Promise.resolve(bufferResponse('some-real-bytes-here'));
    }) as any;
    const provider = new ArkImageGenProvider();

    const [candidate] = await provider.generateCandidates({
      referenceImageUrl: 'https://r2/main.jpg',
      sceneText: 'x',
      count: 1,
    });

    expect(Buffer.isBuffer(candidate.buffer)).toBe(true);
    expect(candidate.buffer.length).toBeGreaterThan(0);
    expect(candidate.contentType).toBe('image/png');
  });
});
