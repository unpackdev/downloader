// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IUniswapV2Pair.sol";

import "./ProviderAwareOracle.sol";
import "./FixedPointMathLib.sol";

contract UniswapV2LPPriceOracle is ProviderAwareOracle {
    using FixedPointMathLib for uint256;

    /**
     * @dev sets up the Price Oracle
     */
    constructor(address _provider) ProviderAwareOracle(_provider) {}

    /**
     * OPERATIONAL METHODS *****
     */

    /**
     * @dev returns the TWAP for the provided pair as of the last update
     */
    function getSafePrice(address _lpToken) public view returns (uint256) {
        return _getLPPrice(_lpToken, true);
    }

    /**
     * @dev returns the current "unsafe" price that can be easily manipulated
     */
    function getCurrentPrice(address _lpToken) external view returns (uint256) {
        return _getLPPrice(_lpToken, false);
    }

    /**
     * @dev updates the TWAP (if enough time has lapsed) and returns the current safe price
     */
    function updateSafePrice(address _lpToken) external view returns (uint256) {
        return getSafePrice(_lpToken);
    }

    // internal functions

    function _getLPPrice(address pair, bool isSafePrice) internal view returns (uint256 price) {
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 totalSupply = IUniswapV2Pair(pair).totalSupply();
        (uint256 r0, uint256 r1,) = IUniswapV2Pair(pair).getReserves();
        uint8 dec0 = IERC20Metadata(token0).decimals();
        uint8 dec1 = IERC20Metadata(token1).decimals();
        uint256 sqrtR = (r0 * r1 * (10 ** (36 - dec0 - dec1))).sqrt();

        uint256 p0 = isSafePrice ? provider.getSafePrice(token0) : provider.getCurrentPrice(token0);
        uint256 p1 = isSafePrice ? provider.getSafePrice(token1) : provider.getCurrentPrice(token1);
        uint256 sqrtP = (p0 * p1).sqrt();
        price = (2 * sqrtR * sqrtP) / totalSupply; // in 1E18 precision
    }
}
