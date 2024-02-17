export * from './globals';
import { checkAndReplaceInstallButton } from './addon';
import { createHistoryProxy } from './history';
import { topSites } from './topSites';

createHistoryProxy();

document.addEventListener('load', () => {
  checkAndReplaceInstallButton();
});

const Browser = {
  topSites,
};

console.log('Orion Browser API loaded.');

window.browser = Browser;

export default Browser;
