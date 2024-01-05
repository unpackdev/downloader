
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./UniswapLib.sol";
import "./ISwapQueryHelper.sol";

/**
 * @dev Uniswap helpers
 */
contract UniswapQueryHelper is ISwapQueryHelper {

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        override
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
       return UniswapLib.ethQuote(token, tokenAmount);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = UniswapLib.factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = UniswapLib.WETH();
    }


    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address tokenA, address tokenB) external view override returns (address pair) {
        address _factory = UniswapLib.factory();
        pair = UniswapLib.getPair(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = UniswapLib.getReserves(pair);
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address tokenA,
        address tokenB
    ) external pure override returns (address pair) {
        address _factory = UniswapLib.factory();
        pair = UniswapLib.pairFor(_factory, tokenA, tokenB);
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address token) external view override returns (bool) {
        return UniswapLib.hasPool(token);
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address token) external pure override returns (address[] memory) {
        return UniswapLib.getPathForETHToToken(token);
    }

}
