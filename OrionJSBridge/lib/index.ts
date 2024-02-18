export * from './globals';
import startBrowser, { Browser } from './browser';
import startTab from './tab';

import './types';

startTab();

startBrowser();

export default Browser;
