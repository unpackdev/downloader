// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface ICKPHHook {
    struct KeyURIs {
        string pinkURI;
        string chromeURI;
        string blackURI;
    }

    error ONLY_LOCK_CONTRACT();
}
