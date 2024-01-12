// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IERC20.sol";
import "./SafeERC20.sol";


interface IDODO {
    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);
}

interface IDODOHelper {
    function querySellQuoteToken(IDODO dodo, uint256 amount)
        external
        view
        returns (uint256);
}

abstract contract DodoV1Executor {
    using SafeERC20 for IERC20;

    function swapDodoV1(
        uint256 sellAmount,
        IDODO pool,
        IDODOHelper helper,
        address recipient,
        IERC20 sourceToken,
        IERC20 targetToken,
        bool isSellBase
    ) external {
        sourceToken.safeApprove(address(pool), sellAmount);
        uint256 boughtAmount;
        if (isSellBase) {
            // Sell the Base token directly against the contract
            boughtAmount = pool.sellBaseToken(
                // amount to sell
                sellAmount,
                // min receive amount
                1,
                new bytes(0)
            );
        } else {
            // Need to re-calculate the sell quote amount into buyBase
            boughtAmount = helper.querySellQuoteToken(pool, sellAmount);
            pool.buyBaseToken(
                // amount to buy
                boughtAmount,
                // max pay amount
                sellAmount,
                new bytes(0)
            );
        }
        if (recipient != address(this)) {
            targetToken.safeTransfer(recipient, boughtAmount);
        }
    }
}
