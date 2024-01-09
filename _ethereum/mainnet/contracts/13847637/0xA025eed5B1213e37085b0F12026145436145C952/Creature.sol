// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title NFT
 * Mintjar  - a contract for my non-fungible tokens.
 */
contract Creature is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("MintJar NFT", "MJ", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://api.mintjar.co/assets";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.mintjar.co/default/contract";
    }
}
