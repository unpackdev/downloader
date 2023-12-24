// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC721TokenLocker.sol";

/**
 * @title ERC721TokenLocker enables the temporary transfer lock on a token.
 */
contract ERC721TokenLocker is IERC721TokenLocker {
    uint256 public constant MAX_LOCK_EPOCH = 31536000; // 1 year in seconds
    address public targetContract;
    mapping(uint => UnlockSchedule) public unlockSchedules;
    mapping(uint256 => uint256) private unlockedTokens;
    uint private lastSchedule;
    
    struct UnlockSchedule {
        uint256 maxTokenId;
        uint256 unlockTimestamp;
    }
    
    constructor(address contractAddress) {
        targetContract = contractAddress;
    }
    
    modifier onlyTargetContract() {
        require(targetContract == msg.sender, "Caller does not have permission");
        _;
    }
    
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
    ) external onlyTargetContract {
        require(schedule <= lastSchedule + 1, "Invalid unlock schedule");
        if (schedule > lastSchedule) {
            lastSchedule = schedule;
        }
        unlockSchedules[schedule].maxTokenId = maxTokenId;
        unlockSchedules[schedule].unlockTimestamp = unlockTimestamp;
    } 
    
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
    ) external onlyTargetContract {
        require (
            unlockTimestamp <= block.timestamp ||
            (unlockTimestamp - block.timestamp) <= MAX_LOCK_EPOCH,
            "Invalid timestamp"
        );
        unlockedTokens[tokenId] = unlockTimestamp;
    }

    /**
     * @notice check if a token is currently locked
     * @param tokenId id of the locked token
     * @return boolean if token is locked
     */
    function isLocked(uint256 tokenId) external view returns (bool) {
        if (unlockedTokens[tokenId] > 0 && unlockedTokens[tokenId] < block.timestamp) {
            return false;
        }
        
        for (uint i=0; i<=lastSchedule; i++) {
            if (tokenId <= unlockSchedules[i].maxTokenId) {
                if (unlockSchedules[i].unlockTimestamp > 0 && unlockSchedules[i].unlockTimestamp <= block.timestamp) {
                    return false;
                }
                return true;
            }
        }
        return true;
    }
}