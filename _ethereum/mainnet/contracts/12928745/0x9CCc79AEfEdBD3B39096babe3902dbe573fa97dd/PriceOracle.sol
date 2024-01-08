// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./MToken.sol";

interface PriceOracle {
    /**
      * @notice Get the underlying price of a mToken asset
      * @param mToken The mToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(MToken mToken) external view returns (uint);
}
