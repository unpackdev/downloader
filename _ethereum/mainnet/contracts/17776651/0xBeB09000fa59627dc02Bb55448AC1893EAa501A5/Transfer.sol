// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Transfer {
    struct Pending {
        address token;
        address maker_address;
        uint256 amount;
    }

    struct NativeTokens {
        uint256 toTaker;  // accumulated amount of tokens that will be sent to the taker (receiver)
        uint256 toMakers; // accumulated amount of tokens that will be sent to the makers
    }

    struct Indices {
        uint commandsInd; // current `order.commands` index
        uint batchToApproveInd; // current `batchToApprove` index
        uint permitSignaturesInd; // current `takerPermitsInfo.permitSignatures` index

        uint pendingTransfersLen; // current length of `pendingTransfers`
        uint batchLen; // current length of `batchTransferDetails`
    }
}
