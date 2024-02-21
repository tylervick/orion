export type MessageBody = {
    method: 'topSites' | 'storage' | 'bookmarks';
    payload: object;
};
type MostVisitedURL = {
    url: string;
    title: string;
    favicon: string | undefined;
};
type TopSitesOptions = {
    includeBlocked: boolean | undefined;
    includeFavicon: boolean | undefined;
    includePinned: boolean | undefined;
    includeSearchShortcuts: boolean | undefined;
    limit: number | undefined;
    newtab: boolean | undefined;
};
export interface TopSites {
    get(options: TopSitesOptions): Promise<MostVisitedURL[]>;
}
export declare const topSites: TopSites;
export {};
