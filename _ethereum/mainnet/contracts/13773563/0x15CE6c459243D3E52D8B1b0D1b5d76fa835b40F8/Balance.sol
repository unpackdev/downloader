// SPDX-License-Identifier: CC-BY-NC-ND-4.0

/*
  ____          _               _   _  _____ _____
 |  _ \   /\   | |        /\   | \ | |/ ____(_____)
 | |_) | /  \  | |       /  \  |  \| | |      ___
 |  _ < / /\ \ | |      / /\ \ | . ` | |     (___)
 | |_) / ____ \| |____ / ____ \| |\  | |____ _____
 |____/_/    \_\______/_/    \_\_| \_|\_____(_____)


Balance is the most essential component of humanity.

Whether it is the proposition of work/life balance, social distancing versus human interaction, or simply our souls
seeking equilibrium, -- balance is the vital force we strive for.

In order to create balance, it is essential to explore contrasting sides of the scale to achieve the centerpoint. This
photography exhibition aims to celebrate and set women photographers at the forefront of the NFT ecosystem. Women have
traditionally been underrepresented in the art market and art world, and one of our goals is for the NFT space to fill
a gap in this lack of representation. The images in this exhibition explore components of balance in its various guises,
and we look forward to helping build an NFT Photography community that is welcoming, diverse, and balanced in all
aspects. Join us in achieving this objective.

Curated by Brittany Pierre & Burnish

*ARTISTS*
Angelica Ramirez
Crystal Street
Judy Lindsay
May
MK Raplinger
Pam Voth
Taesirat Yusuf
Brittany Pierre
Burnish

A Physical/Digital Exhibition at imnotArt Chicago
December 10-19, 2021

Physical: 1010 N. Ashland, Chicago IL - https://goo.gl/maps/gyoSKSbUZvGMLHBV7
Metaverse: 2 Exciting Field, Vibes CV - https://www.cryptovoxels.com/parcels/4927

Smart Contract by imnotArt Team:
Ian Olson
Joseph Hirn

*/

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./CoreExhibition721.sol";

contract Balance is CoreExhibition721 {

    // ---
    // Constructor
    // ---

    // @dev Contract constructor.
    constructor() CoreExhibition721(NftOptions({
        name: "Balance",
        symbol: "BALANCE",
        imnotArtBps: 0,
        royaltyBps: 1000,
        startingTokenId: 1,
        maxInvocations: 1000,
        contractUri: "https://ipfs.imnotart.com/ipfs/QmRcf1ozSgiiU2DpjRHbMd8dxjPAmB2Sps4gvkH9721NNp"
    })) {
    }
}