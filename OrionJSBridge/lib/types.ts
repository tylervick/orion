import { HistoryItem } from './history';
import { MessageBody } from './topSites';

declare global {
  export interface Window {
    webkit: {
      messageHandlers: {
        history: {
          postMessage: (message: HistoryItem) => Promise<any>;
        };
        extension: {
          postMessage: (message: MessageBody) => Promise<any>;
        };
      };
    };
  }
}
