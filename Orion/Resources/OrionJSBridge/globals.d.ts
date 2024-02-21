declare global {
    export interface Window {
        browser: any;
        History: {
            _pushState: typeof window.history.pushState;
            _replaceState: typeof window.history.replaceState;
        };
    }
}
export {};
