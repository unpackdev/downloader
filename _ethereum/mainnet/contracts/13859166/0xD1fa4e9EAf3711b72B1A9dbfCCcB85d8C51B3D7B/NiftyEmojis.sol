// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract NiftyEmojis is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("NiftyEmojis", "NIFT", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://api.niftyemojis.app/";
    }
}
