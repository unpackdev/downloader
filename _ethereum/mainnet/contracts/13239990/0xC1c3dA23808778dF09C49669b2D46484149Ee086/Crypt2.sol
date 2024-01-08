// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Crypt2 is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Crypt2", "crypt2", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://crypt2.co.uk/nfts/meta/traits/";
    }

    function contractURI() public pure returns (string memory) {
        return "https:///crypt2.co.uk/nfts/contract/";
    }
}
