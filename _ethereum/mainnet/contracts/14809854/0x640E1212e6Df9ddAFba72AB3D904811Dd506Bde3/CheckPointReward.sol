// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title CheckPointReward library
/// @author UNIFARM
/// @notice help to do a calculation of various checkpoints.
/// @dev all the functions are internally used in the protocol.

library CheckPointReward {
    /**
     * @dev help to find block difference
     * @param from from the blockNumber
     * @param to till the blockNumber
     * @return the blockDifference
     */

    function getBlockDifference(uint256 from, uint256 to) internal pure returns (uint256) {
        return to - from;
    }

    /**
     * @dev calculate number of checkpoint
     * @param from from blockNumber
     * @param to till blockNumber
     * @param epochBlocks epoch blocks length
     * @return checkpoint number of checkpoint
     */

    function getCheckpoint(
        uint256 from,
        uint256 to,
        uint256 epochBlocks
    ) internal pure returns (uint256) {
        uint256 blockDifference = getBlockDifference(from, to);
        return uint256(blockDifference / epochBlocks);
    }

    /**
     * @dev derive current check point in unifarm cohort
     * @dev it will be maximum to unifarm cohort endBlock
     * @param startBlock start block of a unifarm cohort
     * @param endBlock end block of a unifarm cohort
     * @param epochBlocks number of blocks in one epoch
     * @return checkpoint the current checkpoint in unifarm cohort
     */

    function getCurrentCheckpoint(
        uint256 startBlock,
        uint256 endBlock,
        uint256 epochBlocks
    ) internal view returns (uint256 checkpoint) {
        uint256 yfEndBlock = block.number;
        if (yfEndBlock > endBlock) {
            yfEndBlock = endBlock;
        }
        checkpoint = getCheckpoint(startBlock, yfEndBlock, epochBlocks);
    }

    /**
     * @dev derive start check point of user staking
     * @param startBlock start block
     * @param userStakedBlock block on user staked
     * @param epochBlocks number of block in epoch
     * @return checkpoint the start checkpoint of a user
     */

    function getStartCheckpoint(
        uint256 startBlock,
        uint256 userStakedBlock,
        uint256 epochBlocks
    ) internal pure returns (uint256 checkpoint) {
        checkpoint = getCheckpoint(startBlock, userStakedBlock, epochBlocks);
    }
}
