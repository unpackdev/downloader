//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small library to randomize using (min, max, seed)
// all number returned are considered with 3 decimals
library Randomize {
    struct Random {
        uint256 seed;
    }

    /// @notice This function uses seed to return a pseudo random interger between [min and max[
    /// @param random the random seed
    /// @return the pseudo random number
    function next(Random memory random, uint256 min, uint256 max) internal pure returns (uint256) {
        random.seed ^= random.seed << 13;
        random.seed ^= random.seed >> 17;
        random.seed ^= random.seed << 5;
        return min + random.seed % (max - min);
    }
}
