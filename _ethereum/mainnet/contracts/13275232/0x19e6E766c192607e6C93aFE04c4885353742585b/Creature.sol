// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Loot 3D", "LOOT3D", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://ipfs.io/ipfs/QmSaDo4CVjXz8FMPcQzNHbmjKV1EKRzmYfFStht4Sz5nC5/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://ipfs.io/ipfs/QmTGdsPuLMPKQT6niex8kJsFtkXA1PGQE2CpvSAX7ramfR/creatures";
    }
}
