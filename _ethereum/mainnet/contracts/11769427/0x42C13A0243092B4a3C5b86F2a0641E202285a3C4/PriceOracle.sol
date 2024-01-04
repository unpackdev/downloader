pragma solidity ^0.7.4;

import "./PToken.sol";

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    event PriceUpdated(address asset, uint price);

    /**
      * @notice Get the underlying price of a pToken asset
      * @param pToken The pToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(PToken pToken) external view virtual returns (uint);

    function updateUnderlyingPrice(PToken pToken) external virtual returns (uint);
}