import { ArkVideoGenProvider } from './ark-video-gen.provider';
import { ScenePortraitProviderNotConfiguredError } from './errors';

// Contract tests: fully mocked HTTP, never touches the real Ark API. These
// exist to catch a vendor field-name/shape change early — see
// docs/reference/testing.md.

// The real shape ArkVideoGenProvider passes as fetch's second argument (see
// ark-video-gen.provider.ts) — narrower than the DOM `RequestInit` type,
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
  };
}

function bufferResponse(bytes: string, ok = true, status = 200) {
  return {
    ok,
    status,
    arrayBuffer: () => Promise.resolve(Buffer.from(bytes)),
    headers: { get: () => 'video/mp4' },
  };
}

describe('ArkVideoGenProvider', () => {
  const originalFetch = global.fetch;
  const originalApiKey = process.env.ARK_API_KEY;

  beforeEach(() => {
    process.env.ARK_API_KEY = 'test-key';
    process.env.ARK_BASE_URL = 'https://ark.test/api/v3';
  });

  afterEach(() => {
    global.fetch = originalFetch;
    if (originalApiKey === undefined) delete process.env.ARK_API_KEY;
    else process.env.ARK_API_KEY = originalApiKey;
  });

  describe('submitImageToVideo', () => {
    it('throws ScenePortraitProviderNotConfiguredError when ARK_API_KEY is blank', async () => {
      delete process.env.ARK_API_KEY;
      const provider = new ArkVideoGenProvider();

      await expect(
        provider.submitImageToVideo({
          imageUrl: 'https://r2/c1.png',
          motionPrompt: 'x',
          durationSeconds: 5,
        }),
      ).rejects.toBeInstanceOf(ScenePortraitProviderNotConfiguredError);
    });

    it('submits to the tasks endpoint with the auth header and returns providerTaskId', async () => {
      const fetchMock = jest
        .fn()
        .mockImplementation((url: string, init: FetchCallInit = {}) => {
          expect(url).toBe(
            'https://ark.test/api/v3/contents/generations/tasks',
          );
          expect(init.method).toBe('POST');
          expect(init.headers?.Authorization).toBe('Bearer test-key');
          if (typeof init.body !== 'string') {
            throw new Error('Expected a JSON string request body');
          }
          const body = JSON.parse(init.body) as {
            content: { type: string; [key: string]: unknown }[];
          };
          expect(body.content).toEqual(
            expect.arrayContaining([
              expect.objectContaining({
                type: 'image_url',
                image_url: { url: 'https://r2/c1.png' },
              }),
              expect.objectContaining({ type: 'text', text: 'a gentle loop' }),
            ]),
          );
          return Promise.resolve(jsonResponse({ id: 'task-abc123' }));
        });
      global.fetch = fetchMock;
      const provider = new ArkVideoGenProvider();

      const result = await provider.submitImageToVideo({
        imageUrl: 'https://r2/c1.png',
        motionPrompt: 'a gentle loop',
        durationSeconds: 5,
      });

      expect(result).toEqual({ providerTaskId: 'task-abc123' });
    });

    it('throws when the submit response has no task id', async () => {
      global.fetch = jest.fn().mockResolvedValue(jsonResponse({})) as any;
      const provider = new ArkVideoGenProvider();

      await expect(
        provider.submitImageToVideo({
          imageUrl: 'https://r2/c1.png',
          motionPrompt: 'x',
          durationSeconds: 5,
        }),
      ).rejects.toThrow(/no id/);
    });

    it('throws with the response body on a non-2xx submit', async () => {
      global.fetch = jest
        .fn()
        .mockResolvedValue(jsonResponse({ error: 'bad' }, false, 400)) as any;
      const provider = new ArkVideoGenProvider();

      await expect(
        provider.submitImageToVideo({
          imageUrl: 'https://r2/c1.png',
          motionPrompt: 'x',
          durationSeconds: 5,
        }),
      ).rejects.toThrow(/400/);
    });
  });

  describe('pollTask', () => {
    it('returns pending while the task is queued/running', async () => {
      global.fetch = jest
        .fn()
        .mockResolvedValue(jsonResponse({ status: 'running' })) as any;
      const provider = new ArkVideoGenProvider();

      const result = await provider.pollTask('task-abc123');

      expect(result).toEqual({ status: 'pending' });
    });

    it('returns failed when the vendor reports the task failed', async () => {
      global.fetch = jest
        .fn()
        .mockResolvedValue(jsonResponse({ status: 'failed' })) as any;
      const provider = new ArkVideoGenProvider();

      const result = await provider.pollTask('task-abc123');

      expect(result.status).toBe('failed');
    });

    it('returns failed when succeeded but content.video_url is missing', async () => {
      global.fetch = jest
        .fn()
        .mockResolvedValue(
          jsonResponse({ status: 'succeeded', content: {} }),
        ) as any;
      const provider = new ArkVideoGenProvider();

      const result = await provider.pollTask('task-abc123');

      expect(result).toEqual({
        status: 'failed',
        errorMessage: expect.stringContaining('no video_url'),
      });
    });

    it('downloads the video and returns a non-empty Buffer on succeeded', async () => {
      global.fetch = jest.fn().mockImplementation((url: string) => {
        if (url.includes('/tasks/task-abc123')) {
          return Promise.resolve(
            jsonResponse({
              status: 'succeeded',
              content: { video_url: 'https://vendor.example/v1.mp4' },
            }),
          );
        }
        if (url === 'https://vendor.example/v1.mp4') {
          return Promise.resolve(bufferResponse('real-video-bytes'));
        }
        throw new Error(`Unexpected fetch call: ${url}`);
      }) as any;
      const provider = new ArkVideoGenProvider();

      const result = await provider.pollTask('task-abc123');

      expect(result.status).toBe('succeeded');
      if (result.status === 'succeeded') {
        expect(Buffer.isBuffer(result.video.buffer)).toBe(true);
        expect(result.video.buffer.length).toBeGreaterThan(0);
        expect(result.video.contentType).toBe('video/mp4');
      }
    });

    it('returns failed when the video download itself fails', async () => {
      global.fetch = jest.fn().mockImplementation((url: string) => {
        if (url.includes('/tasks/task-abc123')) {
          return Promise.resolve(
            jsonResponse({
              status: 'succeeded',
              content: { video_url: 'https://vendor.example/v1.mp4' },
            }),
          );
        }
        return Promise.resolve(bufferResponse('', false, 404));
      }) as any;
      const provider = new ArkVideoGenProvider();

      const result = await provider.pollTask('task-abc123');

      expect(result).toEqual({
        status: 'failed',
        errorMessage: expect.stringContaining('Failed to download'),
      });
    });

    it('throws (does not silently poll forever) when ARK_API_KEY is blank', async () => {
      delete process.env.ARK_API_KEY;
      const provider = new ArkVideoGenProvider();

      await expect(provider.pollTask('task-abc123')).rejects.toBeInstanceOf(
        ScenePortraitProviderNotConfiguredError,
      );
    });
  });
});
