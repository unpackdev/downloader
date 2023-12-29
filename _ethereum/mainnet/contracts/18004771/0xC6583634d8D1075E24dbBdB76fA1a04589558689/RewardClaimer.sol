// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC20.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title RewardClaimer
 * @author 5thWeb Via WhiteLab3l
 * @notice A contract that allows holders of a specific ERC721 token to claim rewards in the form of an ERC20 token.
 */
contract RewardClaimer is Ownable {

    IERC20 public rewardToken;
    IERC721Enumerable public nftToken;

    mapping(uint256 => uint256) public lastClaimed;
    mapping(uint256 => uint256) public rewardsClaimed;

    uint256 public rewardPerNFT;

    uint256 public constant ONE_WEEK = 7 days;

    /**
     * @dev Constructor that sets the addresses for the ERC20 and ERC721 tokens.
     * @param _rewardToken Address of the ERC20 reward token.
     * @param _nftToken Address of the ERC721 token.
     */
    constructor(address _rewardToken, address _nftToken) {
        rewardToken = IERC20(_rewardToken);
        nftToken = IERC721Enumerable(_nftToken);
    }

    /**
     * @dev Allows a user to claim rewards for specified NFTs.
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
     * @dev Internal function to process the reward claim for a specific NFT.
     * @param tokenId The ID of the NFT token.
     */
    function _claimReward(uint256 tokenId) internal {
        uint256 pendingReward = rewardPerNFT - rewardsClaimed[tokenId];
        require(pendingReward > 0, "No rewards available for this NFT");

        lastClaimed[tokenId] = block.timestamp;
        rewardsClaimed[tokenId] += pendingReward;

        rewardToken.transfer(msg.sender, pendingReward);
    }

    /**
     * @dev View function to check the longest time remaining for the next claim across specified NFTs owned by the caller.
     * @param tokenIds An array of NFT token IDs owned by the caller.
     * @return The longest time remaining in seconds until the next claim is available.
     */
    function timeUntilNextClaimForWallet(uint256[] calldata tokenIds) external view returns (uint256) {
        require(tokenIds.length > 0, "No token IDs provided");

        uint256 longestWait = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftToken.ownerOf(tokenId) == msg.sender, "Not the token owner");

            uint256 timeForThisToken = (lastClaimed[tokenId] + ONE_WEEK) - block.timestamp;

            if (timeForThisToken > longestWait) {
                longestWait = timeForThisToken;
            }
        }

        return longestWait;
    }

    /**
     * @dev Allows the owner to deposit rewards for distribution.
     * @param amount The amount of ERC20 tokens to deposit.
     */
    function depositRewards(uint256 amount) external onlyOwner {
        uint256 totalSupply = nftToken.totalSupply();
        require(totalSupply > 0, "No NFTs minted yet");

        require(rewardToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Distribute the deposited rewards among the existing NFTs
        rewardPerNFT += amount / totalSupply;
    }

    /**
     * @dev Allows the owner to withdraw ERC20 tokens in case of an emergency.
     * @param amount The amount of ERC20 tokens to withdraw.
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        rewardToken.transfer(msg.sender, amount);
    }
}