// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWowmaxRouter.sol";

// @title Hashflow router interface
interface IHashflowRouter {
    struct RFQTQuote {
        address pool;
        address externalAccount;
        address trader;
        address effectiveTrader;
        address baseToken;
        address quoteToken;
        uint256 effectiveBaseTokenAmount;
        uint256 maxBaseTokenAmount;
        uint256 maxQuoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }

    function tradeSingleHop(RFQTQuote calldata quote) external payable;
}

// @title Hashflow library
// @notice Functions to swap tokens on Hashflow protocol
library Hashflow {
    using SafeERC20 for IERC20;

    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IHashflowRouter.RFQTQuote memory quote = abi.decode(swapData.data, (IHashflowRouter.RFQTQuote));
        //slither-disable-next-line unused-return //it's safe to ignore
        IERC20(from).approve(swapData.addr, amountIn);
        if (amountIn < quote.maxBaseTokenAmount) {
            quote.effectiveBaseTokenAmount = amountIn;
        }
        uint256 balanceBefore = IERC20(swapData.to).balanceOf(address(this));
        IHashflowRouter(swapData.addr).tradeSingleHop(quote);
        amountOut = IERC20(swapData.to).balanceOf(address(this)) - balanceBefore;
    }
}
