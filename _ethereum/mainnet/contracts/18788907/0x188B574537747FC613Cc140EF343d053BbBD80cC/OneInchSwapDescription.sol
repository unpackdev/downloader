//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

struct OneInchSwapDescription {
        address srcToken;
        address dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
}