/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./LibEthUsdOracle.sol";
import "./SafeMath.sol";
import "./C.sol";

/**
 * @title Eth Usd Oracle Library
 * @notice Contains functionalty to fetch the manipulation resistant USD price of different tokens.
 * @dev currently supports:
 * - ETH/USD price
 **/
library LibUsdOracle {

    using SafeMath for uint256;

    function getUsdPrice(address token) internal view returns (uint256) {
        return getUsdPrice(token, 0);
    }

    /**
     * @dev Returns the price of a given token in in USD with the option of using a lookback.
     * `lookback` should be 0 if the instantaneous price is desired. Otherwise, it should be the
     * TWAP lookback in seconds.
     * If using a non-zero lookback, it is recommended to use a substantially large `lookback`
     * (> 900 seconds) to protect against manipulation.
     */
    function getUsdPrice(address token, uint256 lookback) internal view returns (uint256) {
        if (token == C.WETH) {
            uint256 ethUsdPrice = LibEthUsdOracle.getEthUsdPrice(lookback);
            if (ethUsdPrice == 0) return 0;
            return uint256(1e24).div(ethUsdPrice);
        }
        revert("Oracle: Token not supported.");
    }
}
