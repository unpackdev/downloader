// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract SolidMemes is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("SolidMemes", "MEME", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://api.solidmemes.com/";
    }
}
