import type { Options } from 'amqplib/properties';

export function getChatDlqAssertOptions(): Options.AssertQueue {
  return { durable: true };
}

export function getChatQueueAssertOptions(dlq: string): Options.AssertQueue {
  return {
    durable: true,
    arguments: {
      'x-dead-letter-exchange': '',
      'x-dead-letter-routing-key': dlq,
    },
  };
}
