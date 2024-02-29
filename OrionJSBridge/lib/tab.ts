import { observeInstallButtonWrapper } from './install-button';

// Tab-specific logic, such as streaming history to WKWebView
// not intended to be used in other contexts or by web extensions
const Tab = {
  observeInstallButtonWrapper,
};

const start = () => {
  Tab.observeInstallButtonWrapper();
  console.debug('Orion Tab API loaded.');
};

export default start;
