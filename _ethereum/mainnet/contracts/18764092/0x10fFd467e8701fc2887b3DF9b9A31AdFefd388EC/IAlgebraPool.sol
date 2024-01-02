// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPool {
    /// @notice The globalState structure in the pool stores many values but requires only one slot
    /// and is exposed as a single method to save gas when accessed externally.
    /// @return price The current price of the pool as a sqrt(dToken1/dToken0) Q64.96 value;
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run;
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick boundary;
    /// @return prevInitializedTick The previous initialized tick
    /// @return fee The last pool fee value in hundredths of a bip, i.e. 1e-6
    /// @return timepointIndex The index of the last written timepoint
    /// @return communityFee The community fee percentage of the swap fee in thousandths (1e-3)
    /// @return unlocked Whether the pool is currently locked to reentrancy
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            int24 prevInitializedTick,
            uint16 fee,
            uint16 timepointIndex,
            uint8 communityFee,
            bool unlocked
        );
}
