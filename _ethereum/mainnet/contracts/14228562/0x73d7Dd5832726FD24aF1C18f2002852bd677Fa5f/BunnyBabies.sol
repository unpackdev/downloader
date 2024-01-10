// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * Bunny Babies by crocpot.io
 */
contract BunnyBabies is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
    ERC721Tradable("Bunny Babies", "BUN", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://bunnies.crocpot.io/token/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://bunnies.crocpot.io/token";
    }
}
