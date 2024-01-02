// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface ICKPHHook {
    struct KeyURIs {
        string pinkURI;
        string chromeURI;
        string blackURI;
        string unrevealedURI;
    }

    struct Addresses {
        address owner;
        address lock;
    }

    error ONLY_LOCK_CONTRACT();
    error ONLY_MANAGER_OR_OWNER();
}
