// SPDX-License-Identifier: CC-BY-NC-ND-4.0

/*

o-O-o o  o o--o       o-o  o-o  o     o-o  o--o   o-o       o-o  o--o      o-o  o--o o   o
  |   |  | |         /    o   o |    o   o |   | |         o   o |        |     |     \ /
  |   O--O O-o      O     |   | |    |   | O-Oo   o-o      |   | O-o       o-o  O-o    O
  |   |  | |         \    o   o |    o   o |  \      |     o   o |            | |     / \
  o   o  o o--o       o-o  o-o  O---o o-o  o   o o--o       o-o  o        o--o  o--o o   o

*/

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./CoreDrop721.sol";

contract TheColorsOfSex is CoreDrop721 {

    // ---
    // Constructor
    // ---

    // @dev Contract constructor.
    constructor() CoreDrop721(
        NftOptions({
            name: "The Colors of Sex",
            symbol: "COLORSOFSEX",
            imnotArtBps: 0,
            royaltyBps: 1000,
            startingTokenId: 1,
            maxInvocations: 96,
            contractUri: "https://ipfs.imnotart.com/ipfs/QmcRZPgZr598bcQVeHbRUoeLvbnFg6pizc5TyWKJz2x6Dh"
        }), 
        DropOptions({
            metadataBaseUri: "https://api.imnotart.com/",
            mintPriceInWei: 0.069 ether,
            maxQuantityPerTransaction: 3,
            autoPayout: false,
            active: false,
            presaleMint: false,
            presaleActive: false,
            imnotArtPayoutAddress: msg.sender,
            artistPayoutAddress: msg.sender,
            maxPerWalletEnabled: true,
            maxPerWalletQuantity: 3,
            artistProofs: true,
            artistProofsQuantity: 6,
            artistProofsAddress: address(0x5d4F804d2738a599f9Af385faDe86547f3fBE3c0)
        })
    ){
    }
}