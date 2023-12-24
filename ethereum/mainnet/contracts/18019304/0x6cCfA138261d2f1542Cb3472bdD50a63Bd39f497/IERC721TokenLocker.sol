// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IERC721TokenLocker {
    /**
     * @notice set unlock schedule for tokens
     * @param maxTokenId id that will be unlocked after given timestamp
     * @param unlockTimestamp timestamp when tokens unlock
     * @param schedule unlock schedule order
     * Requirements
     * - the caller must be target contract
     */
    function setUnlockSchedule(
        uint256 maxTokenId,
        uint256 unlockTimestamp,
        uint schedule
    ) external;
    
    /**
     * @notice set unlock timestamp for a token
     * @param tokenId id of the locked token
     * @param unlockTimestamp timestamp when tokens unlock
     * Requirements
     * - the caller must be target contract
     */
    function setUnlockTimestampForToken(
        uint256 tokenId,
        uint256 unlockTimestamp
    ) external;

    /**
     * @notice check if a token is currently locked
     * @param tokenId id of the locked token
     * @return boolean if token is locked
     */
    function isLocked(uint256 tokenId) external view returns (bool);
}