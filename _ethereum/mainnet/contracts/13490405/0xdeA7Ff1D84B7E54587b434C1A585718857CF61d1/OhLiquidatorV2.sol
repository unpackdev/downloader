// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./ILiquidatorV2.sol";
import "./IRegistry.sol";
import "./OhSubscriber.sol";

/// @title Oh! Finance Liquidator V2
/// @notice Contract to manage standard token liquidations on UniswapV2-like routers
/// @dev This version generalizes the router address
contract OhLiquidatorV2 is OhSubscriber, ILiquidatorV2 {
    using SafeERC20 for IERC20;

    /// @notice mapping of router to source token to desired token to swap liquidation route
    mapping(address => mapping(address => mapping(address => address[]))) public swapRoutes;

    /// @notice mapping of source token to desired token to router used for liquidation
    mapping(address => mapping(address => address)) public tokenSwapRouter;

    /// @notice address of WETH
    address public override weth;

    /// @notice Initialize the Liquidator with Uniswap and Sushiswap V2 Router Addresses
    /// @param _registry The address of the Registry
    /// @param _weth The address of WETH or the wrapped underlying coin
    constructor(
        address _registry,
        address _weth
    ) OhSubscriber(_registry) {
        weth = _weth;
    }

    /// @notice Liquidate an amount of 'from' tokens to 'to' tokens from this address
    /// @dev Send proceeds to the caller, `msg.sender` will typically be a Strategy
    /// @param recipient The recipient of the swap
    /// @param from The token we have
    /// @param to The token we want to swap to
    /// @param amount The amount of 'from' tokens to swap
    /// @param minOut The minimum output amount accepted
    /// @return The amount of 'to' tokens received
    function liquidate(
        address recipient,
        address from,
        address to,
        uint256 amount,
        uint256 minOut
    ) external override returns (uint256) {
        // get the router address and swap path
        address router = tokenSwapRouter[from][to];
        address[] memory path = swapRoutes[router][from][to];

        // increase allowance and swap
        IERC20(from).safeIncreaseAllowance(router, amount);
        uint256[] memory output = IUniswapV2Router02(router).swapExactTokensForTokens(amount, minOut, path, recipient, block.timestamp);

        // return amount received
        return output[path.length - 1];
    }

    /// @notice Set liquidation route for a token pair on Uniswap
    /// @param from The token that we have
    /// @param to The token that we want
    /// @param path The swap path used to get the desired token
    function setSwapRoutes(
        address router,
        address from,
        address to,
        address[] memory path
    ) external onlyGovernance {
        uint256 length = path.length;

        require(from == path[0], "Liquidator: Invalid From");
        require(to == path[length - 1], "Liquidator: Invalid To");

        tokenSwapRouter[from][to] = router;
        swapRoutes[router][from][to] = path;
    }

    /// @notice Get the router and swap path for a token pair
    /// @param from The token that we have
    /// @param to The token that we want
    function getSwapInfo(address from, address to) external view override returns (address router, address[] memory path) {
        router = tokenSwapRouter[from][to];
        path = swapRoutes[router][from][to];
    }
}
