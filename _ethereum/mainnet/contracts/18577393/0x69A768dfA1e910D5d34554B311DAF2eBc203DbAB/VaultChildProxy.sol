// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Proxy.sol";
import "./IDiamondReadable.sol";

contract VaultChildProxy is Proxy {
    address private immutable DIAMOND;

    constructor(address diamond) {
        DIAMOND = diamond;
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(DIAMOND).facetAddress(msg.sig);
    }
}
