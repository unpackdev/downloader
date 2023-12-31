// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

error ShuffleIdMaxAmountMissmatch();
error ShuffleIdMaxAmountExceed();

/// @notice Library to get pseudo random number and get shuffled token Ids
library ShuffleId {
    using ShuffleId for IdMatrix;

    struct IdMatrix {
        uint256 _count;
        /// @dev The maximum count of tokens token tracker will hold.
        uint256 _max;
        // Used for random index assignment
        mapping(uint256 => uint256) _matrix;
    }

    function count(IdMatrix storage self) internal view returns (uint256) {
        return self._count;
    }
    function max(IdMatrix storage self) internal view returns (uint256) {
        return self._max;
    }


    /// Update the max supply for the collection
    /// @param supply the new token supply.
    /// @dev create additional token supply for this collection.
    function setMax(IdMatrix storage self, uint256 supply) internal {
        if (self._count >= supply) revert ShuffleIdMaxAmountMissmatch();
        self._max = supply;
    }

    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function next(IdMatrix storage self) internal returns (uint256) {
        if (self._count >= self._max) revert ShuffleIdMaxAmountExceed();
        uint256 maxIndex = self._max - self._count;
        uint256 random = diceRoll(maxIndex, self._count);

        uint256 value = 0;
        if (self._matrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = self._matrix[random];
        }

        // If the last available tokenID is still unused...
        if (self._matrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            self._matrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            self._matrix[random] = self._matrix[maxIndex - 1];
        }
        self._count++;
        return value;
    }

    /// @dev Generate almost random number in range
    /// @return rundom number
    function diceRoll(uint256 range, uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        gasleft(),
                        seed,
                        // block.basefee,
                        block.coinbase,
                        block.difficulty,
                        block.gaslimit,
                        block.timestamp
                    )
                )
            ) % range;
    }
}
