// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IQuoter.sol";

import "./IPositionManager.sol";
import "./IPrimexDNS.sol";
import "./ICurveCalc.sol";
import "./ICurveRegistry.sol";

interface IDexAdapter {
    /**
     * @notice Possible dex types
     */
    enum DexType {
        none, // 0
        UniswapV2, // 1  "uniswap", "sushiswap", "quickswap" (v2)
        UniswapV3, // 2
        Curve, // 3
        Balancer, // 4
        AlgebraV3, // 5
        Meshswap // 6
    }

    /*
     * @param encodedPath Swap path encoded in bytes
     * Encoded differently for different dexes:
     * Uniswap v2 - just encoded array of asset addresses
     * Uniswap v3 - swap path is a sequence of bytes. In Solidity, a path can be built like that:
     *      bytes.concat(bytes20(address(weth)), bytes3(uint24(pool1Fee)), bytes20(address(usdc)), bytes3(uint24(pool2Fee)) ...)
     * Quickswap - swap path is a sequence of bytes. In Solidity, a path can be built like that:
     *      bytes.concat(bytes20(address(weth)), bytes20(address(usdc)), bytes20(address(usdt) ...)
     * Curve - encoded array of asset addresses and pool addresses
     * Balancer - encoded array of asset addresses, pool ids and asset limits
     * @param _amountIn TokenA amount in
     * @param _amountOutMin Min tokenB amount out
     * @param _to Destination address for swap
     * @param _deadline Timestamp deadline for swap
     * @param _dexRouter Dex router address
     */
    struct SwapParams {
        bytes encodedPath;
        uint256 amountIn;
        uint256 amountOutMin;
        address to;
        uint256 deadline;
        address dexRouter;
    }

    /*
     * @param encodedPath Swap path encoded in bytes
     * @param _amountIn TokenA amount in
     * @param _dexRouter Dex router address
     */
    struct GetAmountsParams {
        bytes encodedPath;
        uint256 amount; // amountIn or amountOut
        address dexRouter;
    }

    event QuoterChanged(address indexed dexRouter, address indexed quoter);
    event DexTypeChanged(address indexed dexRouter, uint256 indexed dexType);

    /**
     * @param _dexRouter The router address for which the quoter is set
     * @param _quoter The quoter address to set
     */
    function setQuoter(address _dexRouter, address _quoter) external;

    /**
     * @notice Set a dex type for a dex router
     * @param _dexRouter The dex router address
     * @param _dexType The dex type from enum DexType
     */
    function setDexType(address _dexRouter, uint256 _dexType) external;

    /**
     * @notice Swap ERC20 tokens
     * @param _params SwapParams struct
     */
    function swapExactTokensForTokens(SwapParams memory _params) external returns (uint256[3] memory);

    /**
     * @notice Performs chained getAmountOut calculations
     * @notice given an input amount of an asset, returns the maximum output amount of the other asset
     * @param _params GetAmountsParams struct
     */
    function getAmountsOut(GetAmountsParams memory _params) external returns (uint256[3] memory);

    /**
     * @notice Performs chained getAmountIn calculations
     * @notice given an output amount of an asset, returns the maximum input amount of the other asset
     * @param _params GetAmountsParams struct
     */
    function getAmountsIn(GetAmountsParams memory _params) external returns (uint256[3] memory);

    /**
     * @notice Dex type mapping dexRouter => dex type
     */
    function dexType(address) external view returns (DexType);

    /**
     * @notice Mapping from the dexRouter to its quoter
     */
    function quoters(address) external view returns (address);

    /**
     * @return The address of the Registry contract
     */
    function registry() external view returns (address);

    /**
     * @notice Gets the average amount of gas that is required for the swap on some dex
     * @param dexRouter The address of a router
     */
    function getGas(address dexRouter) external view returns (uint256);
}
