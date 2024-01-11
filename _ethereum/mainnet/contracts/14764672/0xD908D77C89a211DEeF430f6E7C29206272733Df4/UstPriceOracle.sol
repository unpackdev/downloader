// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./SafeMathUpgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./PriceOracle.sol";
import "./CErc20.sol";

import "./BasePriceOracle.sol";

/**
 * @title USTPriceOracle
 * @notice Returns prices for UST set to 0
 * @dev Implements `PriceOracle` and `BasePriceOracle`.
 * @author David Lucid <david@rari.capital> (https://github.com/davidlucid)
 */
contract USTPriceOracle is PriceOracle, BasePriceOracle {
    using SafeMathUpgradeable for uint256;
    
    /**
     * @notice USTw token address.
     */
    address public USTw = 0xa693B19d2931d498c5B318dF961919BB4aee87a5;

    /**
     * @notice UST token address.
     */
    address public UST = 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD;

    /**
     * @notice Fetches the token/ETH price, with 18 decimals of precision.
     * @param underlying The underlying token address for which to get the price.
     * @return Price denominated in ETH (scaled by 1e18)
     */
    function price(address underlying) external override view returns (uint) {
        return _price(underlying);
    }

    /**
     * @notice Returns the price in ETH of the token underlying `cToken`.
     * @dev Implements the `PriceOracle` interface for Fuse pools (and Compound v2).
     * @return Price in ETH of the token underlying `cToken`, scaled by `10 ** (36 - underlyingDecimals)`.
     */
    function getUnderlyingPrice(CToken cToken) external override view returns (uint) {
        address underlying = CErc20(address(cToken)).underlying();
        // Comptroller needs prices to be scaled by 1e(36 - decimals)
        // Since `_price` returns prices scaled by 18 decimals, we must scale them by 1e(36 - 18 - decimals)
        return _price(underlying).mul(1e18).div(10 ** uint256(ERC20Upgradeable(underlying).decimals()));
    }

    /**
     * @notice Fetches the token/ETH price, with 18 decimals of precision.
     */
    function _price(address token) internal view returns (uint) {
        require(token == UST || token == USTw, "Invalid token passed to UstPriceOracle.");
        return 0;
    }
}
