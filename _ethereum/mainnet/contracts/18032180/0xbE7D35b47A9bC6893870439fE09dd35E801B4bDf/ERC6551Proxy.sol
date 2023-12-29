// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Proxy.sol";
import "./CNPYStore.sol";

contract ERC6551Proxy is Proxy {
    CNPYStore immutable store;

    constructor(CNPYStore _store) {
        store = _store;
    }

    function _implementation() internal view virtual override returns (address) {
        return store.implementation();
    }
}
