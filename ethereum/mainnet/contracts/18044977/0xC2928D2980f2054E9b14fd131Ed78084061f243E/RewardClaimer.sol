// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title RewardClaimer
 * @notice A contract that allows holders of specific ERC721 tokens to claim rewards based on specific percentages.
 */
contract RewardClaimer is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    IERC721Enumerable public nftToken;

    mapping(uint256 => uint256) public rewardSplits; // tokenID => reward split (represented as integers)
    mapping(uint256 => uint256) public rewardsForTokenID; // tokenID => reward amount
    mapping(uint256 => uint256) public lastClaimed;

    uint256[] public registeredTokenIds; // Array to keep track of registered tokenIDs

    bool public rewardSplitsSet = false;
    uint256 public constant ONE_WEEK = 7 days;

    /**
     * @notice Constructs the RewardClaimer contract.
     * @param _rewardToken Address of the ERC20 reward token.
     * @param _nftToken Address of the ERC721 token.
     */
    constructor(address _rewardToken, address _nftToken) {
        rewardToken = IERC20(_rewardToken);
        nftToken = IERC721Enumerable(_nftToken);
    }

    /**
     * @notice Allows a user to claim rewards for specified NFTs.
     * @param tokenIds An array of NFT token IDs owned by the caller.
     */
    function claimAllRewards(uint256[] calldata tokenIds) external {
        require(tokenIds.length > 0, "No token IDs provided");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftToken.ownerOf(tokenId) == msg.sender, "Not the token owner");
            if (block.timestamp - lastClaimed[tokenId] > ONE_WEEK) {
                _claimReward(tokenId);
            }
        }
    }

    /**
     * @dev Processes the reward claim for a specific NFT.
     * @param tokenId The ID of the NFT token.
     */
    function _claimReward(uint256 tokenId) internal {
        uint256 pendingReward = rewardsForTokenID[tokenId];
        require(pendingReward > 0, "No rewards available for this NFT");

        rewardsForTokenID[tokenId] = 0;
        lastClaimed[tokenId] = block.timestamp;

        rewardToken.safeTransfer(msg.sender, pendingReward);
    }

    /**
     * @notice Checks the longest time remaining for the next claim across specified NFTs owned by the caller.
     * @param tokenIds An array of NFT token IDs owned by the caller.
     * @return The longest time remaining in seconds until the next claim is available.
     */
    function timeUntilNextClaimForWallet(uint256[] calldata tokenIds) external view returns (uint256) {
        require(tokenIds.length > 0, "No token IDs provided");

        uint256 longestWait = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 timeForThisToken = (lastClaimed[tokenId] + ONE_WEEK) - block.timestamp;

            if (timeForThisToken > longestWait) {
                longestWait = timeForThisToken;
            }
        }

        return longestWait;
    }

    /**
     * @notice Allows the owner to deposit rewards for distribution.
     * @param amount The amount of ERC20 tokens to deposit.
     */
    function depositRewards(uint256 amount) external onlyOwner {
        require(rewardSplitsSet, "Reward splits not initialized");
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);

        for (uint256 i = 0; i < registeredTokenIds.length; i++) {
            uint256 tokenId = registeredTokenIds[i];
            uint256 rewardForThisTokenID = (amount * rewardSplits[tokenId]) / 10000;
            rewardsForTokenID[tokenId] += rewardForThisTokenID;
        }
    }

    /**
     * @notice Allows the owner to set reward splits for specific tokenIDs.
     * @param tokenIds An array of NFT token IDs.
     * @param splits An array of reward splits corresponding to the tokenIDs.
     */
    function setRewardSplits(uint256[] calldata tokenIds, uint256[] calldata splits) external onlyOwner {
        require(!rewardSplitsSet, "Reward splits have already been set");
        require(tokenIds.length == splits.length, "Mismatched arrays");
    
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(splits[i] == 25 || splits[i] == 50 || splits[i] == 100 || splits[i] == 300 || splits[i] == 600 || splits[i] == 1500, "Invalid split value");
            rewardSplits[tokenIds[i]] = splits[i];
            registeredTokenIds.push(tokenIds[i]);
        }
        rewardSplitsSet = true;
    }

    /**
     * @notice Allows the owner to reset the time limiter for all registered tokenIDs.
     */
    function resetTimeLimiterForAll() external onlyOwner {
        for (uint256 i = 0; i < registeredTokenIds.length; i++) {
            uint256 tokenId = registeredTokenIds[i];
            lastClaimed[tokenId] = 0;
        }
    }

    /**
     * @notice Allows the owner to withdraw ERC20 tokens in case of an emergency.
     * @param amount The amount of ERC20 tokens to withdraw.
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        rewardToken.safeTransfer(msg.sender, amount);
    }
}
