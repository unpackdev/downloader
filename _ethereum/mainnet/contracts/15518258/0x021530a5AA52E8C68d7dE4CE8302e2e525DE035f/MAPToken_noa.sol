// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract noaMAPToken is ERC721Tradable {
    constructor(address _proxyRegistryAddress) ERC721Tradable("NOA", "MAP", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://map.j-wave.co.jp/meta/json/noa/1";
    }

}