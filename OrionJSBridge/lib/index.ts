export * from './globals';
import { createHistoryProxy } from './history';
import { topSites } from './topSites';

createHistoryProxy();

const Browser = {
  topSites,
};

console.log('Orion Browser API loaded.');

window.browser = Browser;

export default Browser;
