// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ConstantsLib.sol";

library PseudoRandomLib {
    uint256 internal constant SET_BIT_NOT_FOUND = 1000;
    uint256 internal constant allOnes = ~uint256(0);

    /**
     * @dev derives a new random number from a previous one
     */
    function deriveNewRandomNumber(uint256 randNum) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(randNum)));
    }

    /**
     * @dev derives a pseudo random number using a seed and block difficulty (randao)
     */
    function getPseudoRandomNumber(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, block.prevrandao)));
    }

    function keepBitsRightOfIndex(uint256 bits, uint256 idx) internal pure returns (uint256) {
        // Shift right to create a mask with ones from position idx up to 255
        uint256 rightMask = allOnes >> (idx + 1);

        // only keep the bits from the right half
        return bits & rightMask;
    }

    function keepBitsLeftOfIndex(uint256 bits, uint256 idx) internal pure returns (uint256) {
        // Shift left to create a mask with ones from position 0 up to idx
        uint256 leftMask = allOnes << (256 - idx);

        return bits & leftMask;
    }

    /**
     * @dev helper which finds a random set bit index in a 256 bit number
     * @dev it utilizes a variation of "random binary" search to efficiently find a set bit index
     * @dev it works by checking a random index, if the bit at the index is set return it
     * @dev if the index is not set, split the bits in half and search the half that contains a set bit
     * @dev if both halves contain a set bit, search the half that is larger
     */
    function findRandomSetBitIndex(
        uint256 originalBits,
        uint256 randNum,
        uint256 maxIndexInclusive
    ) internal pure returns (uint256) {
        uint256 bits = keepBitsLeftOfIndex(originalBits, maxIndexInclusive + 1);
        if (bits == ConstantsLib.EMPTY_BITMAP) return SET_BIT_NOT_FOUND;

        uint256 low;
        uint256 high = maxIndexInclusive;

        while (low < high) {
            randNum = deriveNewRandomNumber(randNum);
            uint256 idx = low + (randNum % (high - low + 1)); // Random index within [low, high] inclusive

            // check if the bit is set
            if (((bits >> (255 - idx)) & 1) == 1) {
                return idx;
            } else {
                uint256 leftHalf = keepBitsLeftOfIndex(bits, idx);
                uint256 rightHalf = keepBitsRightOfIndex(bits, idx);

                if (leftHalf == ConstantsLib.EMPTY_BITMAP) {
                    // no set bits in the left half search the right
                    low = idx + 1;
                } else if (rightHalf == ConstantsLib.EMPTY_BITMAP) {
                    // no set bits in the right half search the left
                    high = idx - 1;
                } else if ((idx - low) < (high - idx)) {
                    // The right half is larger search the right
                    low = idx + 1;

                    // only keep the upper bits
                    bits = rightHalf;
                } else {
                    // The lower half is larger or the halves are equal
                    high = idx - 1;

                    // only keep the lower bits
                    bits = leftHalf;
                }
            }
        }

        // If there is only one bit left, it must be set
        return low;
    }
}
