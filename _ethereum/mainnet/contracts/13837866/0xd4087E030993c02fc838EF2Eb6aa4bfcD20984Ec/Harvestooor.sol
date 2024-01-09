// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Router02.sol";
import "./ISwapRouter.sol";

contract Harvestooor {
    using SafeERC20 for IERC20;

    uint256 private constant DEADLINE = 2**256 - 1; // max uint

    ISwapRouter02 public immutable uniEx;
    IUniswapV2Router02 public immutable sushiEx;

    constructor(ISwapRouter02 _uniEx, IUniswapV2Router02 _sushiEx) {
        uniEx = _uniEx;
        sushiEx = _sushiEx;
    }

    /**
     * @dev Tax-loss harvest a token by swapping in and swapping out.
     * @notice Uses Uniswap V2 for liquidity.
     * @notice Does not do route-finding, so caller must supply the best exchange token.
     * @notice Does not support fee-on-transfer tokens.
     * @notice Use WETH address in exchangeToken for ETH swaps.
     *
     * @param harvestToken: the token to harvest
     * @param exchangeToken: the token to exchange against for the harvest
     * @param amount: the amount of token to harvest (must be approved)
     * @param minReturn: the minimum amount to receive after the harvest (i.e. slippage)
     */
    function harvestUniV2(
        IERC20 harvestToken,
        IERC20 exchangeToken,
        uint256 amount,
        uint256 minReturn
    ) external {
        // Withdraw token
        harvestToken.safeTransferFrom(msg.sender, address(this), amount);
        harvestToken.approve(address(uniEx), amount);

        // Swap one way - 0 return acceptable because second swap min is enforced
        uint256 amountIntermediate = swapV2(address(harvestToken), address(exchangeToken), amount, 0, address(this));

        // Approve the exchange token
        exchangeToken.approve(address(uniEx), amountIntermediate);

        // Swap back - minReturn now enforced
        // Direct output to caller
        swapV2(address(exchangeToken), address(harvestToken), amountIntermediate, minReturn, msg.sender);
    }

    /**
     * @dev Tax-loss harvest a token by swapping in and swapping out.
     * @notice Uses Uniswap V3 for liquidity.
     * @notice Does not do route-finding, so caller must supply the best exchange token.
     * @notice Does not support fee-on-transfer tokens.
     * @notice Use WETH address in exchangeToken for ETH swaps.
     *
     * @param harvestToken: the token to harvest
     * @param exchangeToken: the token to exchange against for the harvest
     * @param amount: the amount of token to harvest (must be approved)
     * @param minReturn: the minimum amount to receive after the harvest (i.e. slippage)
     * @param feeTier: the fee tier of the pool to swap in
     */
    function harvestUniV3(
        IERC20 harvestToken,
        IERC20 exchangeToken,
        uint256 amount,
        uint256 minReturn,
        uint256 feeTier
    ) external {
        // Withdraw token
        harvestToken.safeTransferFrom(msg.sender, address(this), amount);
        harvestToken.approve(address(uniEx), amount);

        // Swap one way - 0 return acceptable because second swap min is enforced
        uint256 amountIntermediate = swapV3(
            address(harvestToken),
            address(exchangeToken),
            amount,
            0,
            feeTier,
            address(this)
        );

        // Approve the exchange token
        exchangeToken.approve(address(uniEx), amountIntermediate);

        // Swap back - minReturn now enforced
        // Direct output to caller
        swapV3(address(exchangeToken), address(harvestToken), amountIntermediate, minReturn, feeTier, msg.sender);
    }

    /**
     * @dev Tax-loss harvest a token by swapping in and swapping out.
     * @notice Uses Sushiswap for liquidity.
     * @notice Does not do route-finding, so caller must supply the best exchange token.
     * @notice Does not support fee-on-transfer tokens.
     * @notice Use WETH address in exchangeToken for ETH swaps.
     *
     * @param harvestToken: the token to harvest
     * @param exchangeToken: the token to exchange against for the harvest
     * @param amount: the amount of token to harvest (must be approved)
     * @param minReturn: the minimum amount to receive after the harvest (i.e. slippage)
     */
    function harvestSushi(
        IERC20 harvestToken,
        IERC20 exchangeToken,
        uint256 amount,
        uint256 minReturn
    ) external {
        // Withdraw token
        harvestToken.safeTransferFrom(msg.sender, address(this), amount);
        harvestToken.approve(address(sushiEx), amount);

        // Swap one way - 0 return acceptable because second swap min is enforced
        uint256 amountIntermediate = swapSushi(address(harvestToken), address(exchangeToken), amount, 0, address(this));

        // Approve the exchange token
        exchangeToken.approve(address(sushiEx), amountIntermediate);

        // Swap back - minReturn now enforced
        // Direct output to caller
        swapSushi(address(exchangeToken), address(harvestToken), amountIntermediate, minReturn, msg.sender);
    }

    /**
     * @dev Execute exchange on Uniswap V2.
     *
     * @param from: the token address to swap from
     * @param to: the token address to swap to
     * @param amount: the amount to swap
     * @param minReturn: the minimum amount received from the swap
     * @param recipient: the address to deliver swap output to
     *
     * @return amountOut: the amount of the original token returnedå
     */
    function swapV2(
        address from,
        address to,
        uint256 amount,
        uint256 minReturn,
        address recipient
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;

        uint256 amountOut = uniEx.swapExactTokensForTokens(amount, minReturn, path, recipient);

        return amountOut;
    }

    /**
     * @dev Execute exchange on Uniswap V3.
     *
     * @param from: the token address to swap from
     * @param to: the token address to swap to
     * @param amount: the amount to swap
     * @param minReturn: the minimum amount received from the swap
     * @param feeTier: the fee tier of the pool to swap in
     * @param recipient: the address to deliver swap output to
     *
     * @return amountOut: the amount of the original token returned
     */
    function swapV3(
        address from,
        address to,
        uint256 amount,
        uint256 minReturn,
        uint256 feeTier,
        address recipient
    ) internal returns (uint256) {
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
            tokenIn: from,
            tokenOut: to,
            fee: uint24(feeTier),
            recipient: recipient,
            amountIn: amount,
            amountOutMinimum: minReturn,
            sqrtPriceLimitX96: 0
        });

        uint256 amountOut = uniEx.exactInputSingle(params);

        return amountOut;
    }

    /**
     * @dev Execute exchange on Sushiswap.
     *
     * @param from: the token address to swap from
     * @param to: the token address to swap to
     * @param amount: the amount to swap
     * @param minReturn: the minimum amount received from the swap
     * @param recipient: the address to deliver swap output to
     *
     * @return amountOut: the amount of the original token returned
     */
    function swapSushi(
        address from,
        address to,
        uint256 amount,
        uint256 minReturn,
        address recipient
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;

        uint256[] memory amounts = sushiEx.swapExactTokensForTokens(amount, minReturn, path, recipient, DEADLINE);

        return amounts[1];
    }
}
