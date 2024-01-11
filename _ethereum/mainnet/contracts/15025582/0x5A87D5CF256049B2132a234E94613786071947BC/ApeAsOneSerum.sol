// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./NFTCollectionRoyalties.sol";
import "./NFTCollectionWhitelistReserved.sol";
import "./NFTCollectionPausableMint.sol";
import "./NFTCollectionMutableParams.sol";
import "./NFTCollectionBurnable.sol";

contract ApeAsOneSerum is
    NFTCollectionRoyalties,
    NFTCollectionPausableMint,
    NFTCollectionMutableParams,
    NFTCollectionWhitelistReserved,
    NFTCollectionBurnable
{
    constructor()
        NFTCollection(
            "APE as ONE: Serum Box Set", // Name
            "AAS1S", // Symbol
            "ipfs://QmTCSvbqPAP6BLXb89VEcPpDoDfdH2Aubv7KyRQAi3A7ri/", // Base URI
            0.009 ether, // Cost to mint
            8888, // Max supply
            5, // Max mint amount per tx
            0xa0A922EE2fA0eeDB2a2e813E2aa02b34B7A05d2f // Contract owner
        )
        NFTCollectionWhitelistReserved(
            3899, // total reserved for whitelist
            0xda0c36ddd1a34dffb5b2c85adaf5ba94af546b1e374a9e501e3ab4a952af3182, //merkle root
            5 // Total mint amount per wallet
        ) // For the team
        NFTCollectionRoyalties(0xa0A922EE2fA0eeDB2a2e813E2aa02b34B7A05d2f, 750) // 7,5% royalties
    {
        revealed = true; // Instant reveal
        pausedMint = false; // Delayed mint start
    }

    function _mintAmount(uint256 _amount)
        internal
        override(
            NFTCollection,
            NFTCollectionPausableMint,
            NFTCollectionWhitelistReserved
        )
        whenNotPaused
    {
        NFTCollectionWhitelistReserved._mintAmount(_amount);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721A, NFTCollectionRoyalties)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}
