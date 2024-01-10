// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeERC20.sol";

import "./IStakeFor.sol";

/**
 * @title ListingRewardsDistributor
 * @notice It distributes X2Y2 tokens with rolling Merkle airdrops.
 */
contract ListingRewardDistributor is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant BUFFER_ADMIN_WITHDRAW = 3 days;

    IERC20 public immutable x2y2Token;
    IStakeFor public stakingPool;

    // Current reward round (users can only claim pending rewards for the current round)
    uint256 public currentRewardRound;

    // Last paused timestamp
    uint256 public lastPausedTimestamp;

    // Max amount per user in current tree
    uint256 public maximumAmountPerUserInCurrentTree;

    // Total amount claimed by user (in X2Y2)
    mapping(address => uint256) public amountClaimedByUser;

    // Merkle root for a reward round
    mapping(uint256 => bytes32) public merkleRootOfRewardRound;

    // Checks whether a merkle root was used
    mapping(bytes32 => bool) public merkleRootUsed;

    // Keeps track on whether user has claimed at a given reward round
    mapping(uint256 => mapping(address => bool)) public hasUserClaimedForRewardRound;

    event RewardsClaim(address indexed user, uint256 indexed rewardRound, uint256 amount);
    event UpdateListingRewards(uint256 indexed rewardRound);
    event TokenWithdrawnOwner(uint256 amount);
    event StakingPoolUpdate(address newPool);

    /**
     * @notice Constructor
     * @param _x2y2Token address of the X2Y2 token
     */
    constructor(IERC20 _x2y2Token, IStakeFor _stakingPool) {
        x2y2Token = _x2y2Token;
        stakingPool = _stakingPool;
        _pause();
    }

    function updateStakingPool(IStakeFor _stakingPool) external onlyOwner {
        stakingPool = _stakingPool;
        emit StakingPoolUpdate(address(_stakingPool));
    }

    /**
     * @notice Claim pending rewards
     * @param amount amount to claim
     * @param staking direct staking
     * @param merkleProof array containing the merkle proof
     */
    function claim(
        uint256 amount,
        bool staking,
        bytes32[] calldata merkleProof
    ) external whenNotPaused nonReentrant {
        // Verify the reward round is not claimed already
        require(
            !hasUserClaimedForRewardRound[currentRewardRound][msg.sender],
            'Rewards: Already claimed'
        );

        (bool claimStatus, uint256 adjustedAmount) = _canClaim(msg.sender, amount, merkleProof);

        require(claimStatus, 'Rewards: Invalid proof');
        require(maximumAmountPerUserInCurrentTree >= amount, 'Rewards: Amount higher than max');

        // Set mapping for user and round as true
        hasUserClaimedForRewardRound[currentRewardRound][msg.sender] = true;

        // Adjust amount claimed
        amountClaimedByUser[msg.sender] += adjustedAmount;

        // Stake/transfer adjusted amount
        if (staking) {
            require(address(stakingPool) != address(0), 'Cannot stake to address(0)');
            x2y2Token.approve(address(stakingPool), amount);
            stakingPool.depositFor(msg.sender, adjustedAmount);
        } else {
            x2y2Token.safeTransfer(msg.sender, adjustedAmount);
        }

        emit RewardsClaim(msg.sender, currentRewardRound, adjustedAmount);
    }

    /**
     * @notice Update trading rewards with a new merkle root
     * @dev It automatically increments the currentRewardRound
     * @param merkleRoot root of the computed merkle tree
     */
    function updateListingRewards(bytes32 merkleRoot, uint256 newMaximumAmountPerUser)
        external
        onlyOwner
    {
        require(!merkleRootUsed[merkleRoot], 'Owner: Merkle root already used');

        currentRewardRound++;
        merkleRootOfRewardRound[currentRewardRound] = merkleRoot;
        merkleRootUsed[merkleRoot] = true;
        maximumAmountPerUserInCurrentTree = newMaximumAmountPerUser;

        emit UpdateListingRewards(currentRewardRound);
    }

    /**
     * @notice Pause distribution
     */
    function pauseDistribution() external onlyOwner whenNotPaused {
        lastPausedTimestamp = block.timestamp;
        _pause();
    }

    /**
     * @notice Unpause distribution
     */
    function unpauseDistribution() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Transfer X2Y2 tokens back to owner
     * @dev It is for emergency purposes
     * @param amount amount to withdraw
     */
    function withdrawTokenRewards(uint256 amount) external onlyOwner whenPaused {
        require(
            block.timestamp > (lastPausedTimestamp + BUFFER_ADMIN_WITHDRAW),
            'Owner: Too early to withdraw'
        );
        x2y2Token.safeTransfer(msg.sender, amount);

        emit TokenWithdrawnOwner(amount);
    }

    /**
     * @notice Check whether it is possible to claim and how much based on previous distribution
     * @param user address of the user
     * @param amount amount to claim
     * @param merkleProof array with the merkle proof
     */
    function canClaim(
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool, uint256) {
        return _canClaim(user, amount, merkleProof);
    }

    /**
     * @notice Check whether it is possible to claim and how much based on previous distribution
     * @param user address of the user
     * @param amount amount to claim
     * @param merkleProof array with the merkle proof
     */
    function _canClaim(
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal view returns (bool, uint256) {
        // Compute the node and verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(user, amount));
        bool canUserClaim = MerkleProof.verify(
            merkleProof,
            merkleRootOfRewardRound[currentRewardRound],
            node
        );

        if ((!canUserClaim) || (hasUserClaimedForRewardRound[currentRewardRound][user])) {
            return (false, 0);
        } else {
            return (true, amount - amountClaimedByUser[user]);
        }
    }
}
