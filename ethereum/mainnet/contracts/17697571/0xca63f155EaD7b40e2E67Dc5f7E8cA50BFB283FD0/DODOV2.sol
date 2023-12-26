// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWowmaxRouter.sol";

// @title DODO v2 pool interface
interface IDODOV2Pool {
    function sellBase(address to) external returns (uint256);

    function sellQuote(address to) external returns (uint256);
}

// @title DODO v2 library
// @notice Functions to swap tokens on DODO v2 protocol
library DODOV2 {
    uint8 internal constant BASE_TO_QUOTE = 0;

    using SafeERC20 for IERC20;

    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeTransfer(swapData.addr, amountIn);
        uint8 direction = abi.decode(swapData.data, (uint8));

        if (direction == BASE_TO_QUOTE) {
            amountOut = IDODOV2Pool(swapData.addr).sellBase(address(this));
        } else {
            amountOut = IDODOV2Pool(swapData.addr).sellQuote(address(this));
        }
    }
}
