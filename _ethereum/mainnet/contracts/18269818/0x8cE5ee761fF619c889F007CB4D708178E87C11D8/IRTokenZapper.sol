// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "./IERC20.sol";

struct Call {
    address to;
    bytes data;
    uint256 value;
}

struct ZapERC20Params {
    // Token to zap
    IERC20 tokenIn;
    // Total amount to zap / pull from user
    uint256 amountIn;
    // Smart contract calls to execute to produce 'amountOut' of 'tokenOut'
    Call[] commands;
    // RTokens the user requested
    uint256 amountOut;
    // RToken to issue
    IERC20 tokenOut;

    IERC20[] tokensUsedByZap;
}

interface FacadeRead {
    function maxIssuable(RToken rToken, address account) external returns (uint256);
}

interface RToken {
    function issueTo(address recipient, uint256 amount) external;
}
