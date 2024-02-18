export type MessageBody = {
  method: 'topSites' | 'storage' | 'bookmarks';
  payload: object;
};

type MostVisitedURL = {
  url: string;
  title: string;
  favicon: string | undefined;
};

const isMostVisitedURL = (object: any): object is MostVisitedURL => {
  return (
    typeof object.url === 'string' &&
    typeof object.title === 'string' &&
    (typeof object.favicon === 'string' || object.favicon === undefined)
  );
};

type TopSitesOptions = {
  includeBlocked: boolean | undefined; // default: false
  includeFavicon: boolean | undefined; // default: false
  includePinned: boolean | undefined; // default: false
  includeSearchShortcuts: boolean | undefined; // default: false
  limit: number | undefined; // default: 12
  newtab: boolean | undefined; // default: false
};

export interface TopSites {
  get(options: TopSitesOptions): Promise<MostVisitedURL[]>;
}

export const topSites: TopSites = {
  get: async (options) => {
    let body: MessageBody = {
      method: 'topSites',
      payload: options,
    };

    return window.webkit.messageHandlers.extension.postMessage(body).then((response) => {
      console.log('response', response);
      if (Array.isArray(response) && response.every(isMostVisitedURL)) {
        return response;
      }
      throw new Error('Invalid response');
    });
  },
};
