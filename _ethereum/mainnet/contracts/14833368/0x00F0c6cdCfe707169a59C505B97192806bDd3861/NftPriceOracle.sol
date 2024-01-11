// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.16;

import "./CNftInterface.sol";

contract NftPriceOracle {
    /// @notice Indicator that this is a NftPriceOracle contract (for inspection)
    bool public constant isNftPriceOracle = true;

    /**
      * @notice Get the underlying price of a cNft asset
      * @param cNft The cNft to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CNftInterface cNft) external view returns (uint);
}
