// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IERC20.sol";

interface ISwapExecutor {
    struct TargetSwapDescription {
        uint256 tokenRatio;
        bytes data;
    }

    struct SwapDescription {
        IERC20 sourceToken;
        TargetSwapDescription[] swaps;
    }

    function executeSwap(SwapDescription[] calldata swapDescriptions) external payable;
}
