// SPDX-License-Identifier: None
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./LibERC20Token.sol";
import "./ISlingshotModule.sol";

/// @title Slingshot Abstract Uniswap Module
/// @dev   tradeAll is the only unique logic in this module. If true, the remaining
///        portion of a trade is filled in this hop. This addresses the issue of dust
///        to account for slippage and ensure that the user can only receive more of an
///        asset than expected.
abstract contract IUniswapModule is ISlingshotModule {
    using LibERC20Token for IERC20;

    function getRouter() virtual public pure returns (address);

    /// @param amount Amount of the token being exchanged
    /// @param path Array of token addresses to swap
    /// @param tradeAll If true, it overrides totalAmountIn with current token balance
    function swap(
        uint256 amount,
        address[] memory path,
        bool tradeAll
    ) public payable {
        require(path.length > 0, "UniswapModule: path length must be >0");

        if (tradeAll) {
            amount = IERC20(path[0]).balanceOf(address(this));
        }

        address router = getRouter();

        IERC20(path[0]).approveIfBelow(router, amount);

        // for now, we only supporting .swapExactTokensForTokens()
        // amountOutMin is 1, because all we care is final check or output in Slingshot contract
        IUniswapV2Router02(router).swapExactTokensForTokens(
            amount,
            1, // amountOutMin
            path,
            address(this),
            block.timestamp
        );
    }
}
