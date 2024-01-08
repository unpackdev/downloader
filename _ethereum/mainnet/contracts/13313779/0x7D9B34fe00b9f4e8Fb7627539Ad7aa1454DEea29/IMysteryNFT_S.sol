// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IMysteryNFT_S   {
    struct MysteryNFT_S {
        uint32 tokenId;
        uint32 nftType;
        uint32 farmingAcceleratePercent;
        uint32 farmingAccelerateAmount;
        uint32 etfTokenAmount;
        uint32 governTokenAmount;
        uint32 souvenirDiscount;
    }
}