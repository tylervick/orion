const replaceInstallButton = (wrapper: Element) => {
  const installButton = wrapper.querySelector('.InstallButtonWrapper');
  if (!installButton) {
    console.debug('InstallButtonWrapper not found');
    return;
  }
  if (installButton.textContent?.includes('Add to Orion')) {
    console.debug('InstallButtonWrapper already contains "Add to Orion"');
    return;
  }

  // get the href value of the descendant <a> element
  const href = installButton
    .querySelector('a.InstallButtonWrapper-download-link')
    ?.getAttribute('href');

  if (!href) {
    console.debug('href not found');
    return;
  }

  const addButton = document.createElement('div');
  addButton.className = 'AMInstallButton AMInstallButton--noDownloadLink';

  const link = document.createElement('a');
  link.className = 'Button Button--action AMInstallButton-button Button--puffy';
  link.href = href;
  link.textContent = 'Add to Orion';

  addButton.appendChild(link);
  installButton.replaceChildren(addButton);
};

const observeInstallButtonWrapper = () => {
  window.addEventListener('DOMContentLoaded', () => {
    const observer = new MutationObserver((mutationList, _observer) => {
      for (const mutation of mutationList) {
        if (mutation.type === 'childList') {
          const addedNodes = Array.from(mutation.addedNodes);
          for (const node of addedNodes) {
            if (node instanceof Element && node.querySelector('.InstallButtonWrapper')) {
              replaceInstallButton(node);
            }
          }
        }
      }
    });

    const body = document.querySelector('body');
    if (body) {
      observer.observe(body, { childList: true, subtree: true });
    }
  });
};

export { observeInstallButtonWrapper };
