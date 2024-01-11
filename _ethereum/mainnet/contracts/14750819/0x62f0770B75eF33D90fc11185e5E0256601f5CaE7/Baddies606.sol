// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./CoreDrop721.sol";

contract Baddies606 is CoreDrop721 {

    // ---
    // Constructor
    // ---

    // @dev Contract constructor.
    constructor() CoreDrop721(
        NftOptions({
            name: "BADDIES",
            symbol: "BADDIES",
            imnotArtBps: 0,
            royaltyBps: 1000,
            startingTokenId: 1,
            maxInvocations: 606,
            contractUri: "https://ipfs.imnotart.com/ipfs/QmTdmAqY7ev1ZL9TzvZpFV6ZHH6tFqtwFPDS4c3ZPuGtwK"
        }), 
        DropOptions({
            metadataBaseUri: "https://api.imnotart.com/",
            mintPriceInWei: 0.05 ether,
            maxQuantityPerTransaction: 10,
            autoPayout: false,
            active: false,
            presaleMint: false,
            presaleActive: false,
            presaleDifferentMintPrice: false,
            presaleMintPriceInWei: 0.05 ether,
            imnotArtPayoutAddress: msg.sender,
            artistPayoutAddress: msg.sender,
            maxPerWalletEnabled: false,
            maxPerWalletQuantity: 0,
            artistProofs: false,
            artistProofsQuantity: 0,
            artistProofsAddress: msg.sender
        })
    ){
    }
}