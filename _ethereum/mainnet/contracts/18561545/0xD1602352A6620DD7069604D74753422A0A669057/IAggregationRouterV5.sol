// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IAggregationExecutor.sol";
import "./IERC20.sol";

struct SwapInfo {
    IAggregationExecutor executor;
    SwapDescription desc;
    bytes permit;
    bytes data;
}

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
}

interface IAggregationRouterV5 {
    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}
