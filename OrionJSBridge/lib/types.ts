import { MessageBody } from './topSites';

declare global {
  export interface Window {
    webkit: {
      messageHandlers: {
        extension: {
          postMessage: (message: MessageBody) => Promise<unknown>;
        };
      };
    };
  }
}
