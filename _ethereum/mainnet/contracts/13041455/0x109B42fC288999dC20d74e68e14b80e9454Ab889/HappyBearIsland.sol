// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title HappyBearIsland
 * HappyBearIsland - a contract for my non-fungible creatures.
 */
contract HappyBearIsland is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Happy Bear Island", "HBI", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "http://happybearsisland.com/api/creature/";
    }

    function contractURI() public pure returns (string memory) {
        return "http://happybearsisland.com/contract/happy-bear-island";
    }
}
