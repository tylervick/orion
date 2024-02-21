declare global {
    interface History {
        _pushState: typeof window.history.pushState;
        _replaceState: typeof window.history.replaceState;
    }
}
export type HistoryEvent = 'pushState' | 'replaceState' | 'popstate';
export type HistoryItem = {
    event: HistoryEvent;
    href: string | undefined;
    host: string | undefined;
    state: unknown;
    title: string | undefined;
    url: string | undefined;
};
declare const createHistoryProxy: () => void;
export { createHistoryProxy };
