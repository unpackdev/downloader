// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev A pesudo-random number generator that built based on LCG algorithm.
 */
library Random {
    uint256 private constant A = 48271;
    uint256 private constant M = type(uint32).max;
    uint256 private constant C = 0;

    /**
     * @dev Map a number between [0, `idMax`) to another number in the range of [0, `idMax`) randomly
     * with a determined `randomSeed`
     */
    function getRandomizedId(
        uint16 id,
        uint16 idMax,
        uint256 randomSeed
    ) internal pure returns (uint16) {
        uint16[] memory newIdSeq = new uint16[](idMax);
        uint256 seed = randomSeed;

        for (uint16 i = 0; i < idMax; i++) newIdSeq[i] = i;

        for (uint16 i = 0; i < idMax; i++) {
            // LCG
            unchecked { seed = (A * seed + C) % M; }

            uint16 iToSwap = uint16(seed % idMax);
            uint16 temp = newIdSeq[i];
            newIdSeq[i] = newIdSeq[iToSwap];
            newIdSeq[iToSwap] = temp;
        }

        return newIdSeq[id];
    }
}
