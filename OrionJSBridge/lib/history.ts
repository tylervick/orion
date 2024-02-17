import { HistoryEvent } from './types';

declare global {
  interface History {
    _pushState: typeof window.history.pushState;
    _replaceState: typeof window.history.replaceState;
  }
}

const postHistory = (
  state: unknown,
  title: string | undefined,
  url: string | undefined,
  event: HistoryEvent,
) => {
  window.webkit.messageHandlers.history.postMessage({
    event,
    href: window.location.href,
    host: window.location.host,
    title,
    state,
    url,
  });
};

const createHistoryProxy = () => {
  window.history._pushState = window.history.pushState;
  window.history._replaceState = window.history.replaceState;

  window.history.pushState = new Proxy(window.history.pushState, {
    apply(target, thisArg, argArray) {
      const [state, title, url] = argArray;
      postHistory(state, title, url, 'pushState');
      return Reflect.apply(target, thisArg, argArray);
    },
  });

  window.history.replaceState = new Proxy(window.history.replaceState, {
    apply(target, thisArg, argArray) {
      const [state, title, url] = argArray;
      postHistory(state, title, url, 'replaceState');
      return Reflect.apply(target, thisArg, argArray);
    },
  });
};

export { createHistoryProxy };
