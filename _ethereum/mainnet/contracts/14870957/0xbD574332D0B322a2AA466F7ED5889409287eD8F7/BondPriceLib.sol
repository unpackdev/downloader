// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./FixedPointMathLib.sol";

library BondPriceLib {

    using FixedPointMathLib for uint256;

    struct QuotePriceInfo {
        uint256 virtualInputReserves; 
        uint256 lastUpdate;
        uint256 halfLife;
        uint256 levelBips;
    }

    /// @notice Calculates an output for a given bond purchase.
    /// @param input amount of input tokens provided
    /// @param outputReserves physical output reserves (IE CNV)
    /// @param virtualOutputReserves virtual output reserves (IE CNV)
    /// @param virtualInputReserves virtual input reserves (IE DAI)
    /// @param elapsed time since last policy update
    /// @param halfLife rate of change for virtual input reserves 
    /// @param levelBips percentage to growth/decay virtual input reserves to in bips
    function getAmountOut(
        uint256 input,
        uint256 outputReserves,
        uint256 virtualOutputReserves,
        uint256 virtualInputReserves,
        uint256 elapsed,
        uint256 halfLife,
        uint256 levelBips
    ) internal pure returns (uint256 output) {

        // Calculate an output (IE in CNV) given a purchase size of 'input' using 
        // the CPMM formula, while applying an exponential function that grows or decays 
        // virtual input reserves to a specific level. 
        output = input.fmul(
            outputReserves + virtualOutputReserves, 
            expToLevel(virtualInputReserves, elapsed, halfLife, levelBips) + input
        );
    }

    function expToLevel(
        uint256 x, 
        uint256 elapsed, 
        uint256 halfLife,
        uint256 levelBips
    ) internal pure returns (uint256 z) {

        // Shift z right by whole epochs elapsed
        z = x >> (elapsed / halfLife);

        z -= z.fmul(elapsed % halfLife, halfLife) >> 1;
        
        z += FixedPointMathLib.fmul(x - z, levelBips, 1e4);
    }
}