import { Injectable } from '@nestjs/common';
import {
  EventTextGenProvider,
  GenerateEventTextInput,
  GeneratedEventText,
  ResolvedAsset,
} from './event-text-gen.provider';

@Injectable()
export class FakeEventTextGenProvider implements EventTextGenProvider {
  async generate({
    facts,
    language,
  }: GenerateEventTextInput): Promise<GeneratedEventText> {
    await sleep(100);
    const zh = language === 'zh';
    const name = (asset: ResolvedAsset) => (zh ? asset.nameZh : asset.nameEn);
    const gift = facts.giftNameZh
      ? zh
        ? `，${facts.giftNameZh}就在旁边`
        : ` with the ${facts.giftNameEn} nearby`
      : '';
    return {
      title: zh
        ? `${name(facts.atmosphere)}的${name(facts.time)}`
        : `A ${name(facts.atmosphere)} ${name(facts.time)}`,
      body: zh
        ? `TA 在${name(facts.location)}${name(facts.action)}${gift}。`
        : `They were ${name(facts.action)} at the ${name(facts.location)}${gift}.`,
    };
  }
}

function sleep(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}
