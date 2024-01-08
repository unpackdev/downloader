// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract CanvaIslandAvatar is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("CanvaIsland Avatars", "CIA", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://canvaisland.art/opensea-json.php?nft=";
    }

    function contractURI() public pure returns (string memory) {
        return "https://canvaisland.art/opensea-json.php?info";
    }


}
