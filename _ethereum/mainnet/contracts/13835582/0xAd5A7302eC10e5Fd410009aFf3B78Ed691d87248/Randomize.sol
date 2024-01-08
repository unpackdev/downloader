//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small library to randomize using (min, max, seed)
// all number returned are considered with 3 decimals
library Randomize {
    struct Random {
        uint256 seed;
    }

    /// @notice This function uses seed to return a pseudo random interger between 0 and 1000
    ///         Because solidity has no decimal points, the number is considered to be [0, 0.999]
    /// @param random the random seed
    /// @return the pseudo random number (with 3 decimal basis)
    function randomDec(Random memory random) internal pure returns (uint256) {
        random.seed ^= random.seed << 13;
        random.seed ^= random.seed >> 17;
        random.seed ^= random.seed << 5;
        return ((random.seed < 0 ? ~random.seed + 1 : random.seed) % 1000);
    }

    /// @notice return a number between [min, max[, multiplicated by 1000 (for 3 decimal basis)
    /// @param random the random seed
    /// @return the pseudo random number (with 3 decimal basis)
    function randomBetween(
        Random memory random,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256) {
        return min * 1000 + (max - min) * Randomize.randomDec(random);
    }
}
