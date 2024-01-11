// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./LegitArtERC721.sol";
import "./IProxyRegistry.sol";

contract LegitArtERC721Mock is LegitArtERC721 {
    constructor(IProxyRegistry _proxyRegistry) LegitArtERC721(_proxyRegistry) {}
}
