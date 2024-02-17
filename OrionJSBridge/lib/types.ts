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

export type MessageBody = {
  method: 'topSites' | 'storage' | 'bookmarks';
  payload: object;
};

export type HistoryEvent = 'pushState' | 'replaceState' | 'popstate';

export type HistoryItem = {
  event: HistoryEvent;
  href: string | undefined;
  host: string | undefined;
  state: unknown;
  title: string | undefined;
  url: string | undefined;
};
