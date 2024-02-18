import { topSites } from './topSites';

// The Browser object exposing the Orion Browser API, intended to be used by web extensions
export const Browser = {
  topSites,
  // TODO: implement other APIs like activeTab, bookmarks, history, etc.
};

const start = () => {
  window.browser = Browser;
  console.debug('Orion Browser API loaded.');
};

export default start;
