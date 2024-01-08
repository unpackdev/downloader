// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { IERC20 } from "ERC20.sol";


interface IAggregator {
    struct SwapDescription {
        IERC20 fromToken;
        IERC20 toToken;
        address receiver;
        uint256 amount;
        uint256 minReturnAmount;
    }
    function swap(SwapDescription calldata desc, bytes calldata data) external payable returns (uint256 returnAmount);
}
