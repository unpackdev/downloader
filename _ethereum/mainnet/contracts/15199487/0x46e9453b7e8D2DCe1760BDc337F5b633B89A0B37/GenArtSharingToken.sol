// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./GenArtAccess.sol";
import "./IGenArtInterface.sol";

/**
 * @title GenArtSharingToken
 * @notice It handles the distribution of $GENART tokens
 * @notice forked from https://etherscan.io/address/0xbcd7254a1d759efa08ec7c3291b2e85c5dcc12ce#code
 */
contract GenArtSharingToken is ReentrancyGuard, GenArtAccess {
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 shares; // shares of memberships staked
        uint256[] membershipIds;
        uint256 userRewardPerTokenPaid; // user reward per share paid
        uint256 rewards; // pending rewards
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    // Reward rate (block)
    uint256 public currentRewardPerBlock;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    // Total existing shares
    uint256 public totalShares;

    mapping(address => UserInfo) public userInfo;

    IERC20 public immutable genartToken;

    address public genartInterface;

    address public genartMembership;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(
        uint256 numberBlocks,
        uint256 rewardPerBlock,
        uint256 reward
    );
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice Constructor
     * @param _genartToken address of the token staked (GRNART)
     */
    constructor(
        address _genartMembership,
        address _genartToken,
        address _genartInterace
    ) {
        genartToken = IERC20(_genartToken);
        genartInterface = _genartInterace;
        genartMembership = _genartMembership;
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     */
    function deposit(uint256[] memory membershipIds) external nonReentrant {
        // revert if no memberships passed
        require(
            membershipIds.length > 0,
            "GenArtSharing: minimum 1 membership required"
        );
        _deposit(membershipIds);
    }

    function _deposit(uint256[] memory membershipIds) internal {
        // Update reward for user
        _updateReward(msg.sender);

        uint256 shares;
        // send memberships to this contract
        for (uint256 i; i < membershipIds.length; i++) {
            IERC721(genartMembership).transferFrom(
                msg.sender,
                address(this),
                membershipIds[i]
            );

            // 5 shares per gold membership. 1 share for standard memberships
            shares += IGenArtInterface(genartInterface).isGoldToken(
                membershipIds[i]
            )
                ? 5
                : 1;
            // save the membership token Ids
            userInfo[msg.sender].membershipIds.push(membershipIds[i]);
        }

        // adjust internal shares
        userInfo[msg.sender].shares += shares;
        totalShares += shares;

        emit Deposit(msg.sender, shares);
    }

    function harvest() external nonReentrant {
        // // If pending rewards are null, revert
        uint256 amount = _harvest();
        require(amount > 0, "GenArtSharing: zero rewards to harvest");
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function _harvest() internal returns (uint256) {
        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve pending rewards
        uint256 pendingRewards = userInfo[msg.sender].rewards;

        if (pendingRewards == 0) return 0;
        // Adjust user rewards and transfer
        userInfo[msg.sender].rewards = 0;

        // Transfer reward token to sender
        genartToken.safeTransfer(msg.sender, pendingRewards);

        emit Harvest(msg.sender, pendingRewards);

        return pendingRewards;
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     */
    function withdraw() external nonReentrant {
        require(userInfo[msg.sender].shares > 0, "GenArtSharing: zero shares");
        _withdraw();
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(
        uint256 rewardDurationInBlocks,
        address treasury,
        uint256 rewards
    ) external onlyAdmin {
        // Adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = rewards / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (rewards +
                    ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        genartToken.transferFrom(treasury, address(this), rewards);

        emit NewRewardPeriod(
            rewardDurationInBlocks,
            currentRewardPerBlock,
            rewards
        );
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user)
        external
        view
        returns (uint256)
    {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user)
        internal
        view
        returns (uint256)
    {
        return
            ((userInfo[user].shares *
                (_rewardPerToken() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per token
     */
    function _rewardPerToken() internal view returns (uint256) {
        if (totalShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) *
                (currentRewardPerBlock * PRECISION_FACTOR)) /
            totalShares;
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerToken();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens and collect rewards
     */
    function _withdraw() internal {
        // harvest rewards
        _harvest();

        uint256 shares = userInfo[msg.sender].shares;
        uint256[] memory memberships = userInfo[msg.sender].membershipIds;


        // adjust internal shares
        userInfo[msg.sender].shares = 0;
        totalShares -= shares;

        for (uint256 i = memberships.length; i >= 1; i--) {
            userInfo[msg.sender].membershipIds.pop();
            IERC721(genartMembership).transferFrom(
                address(this),
                msg.sender,
                memberships[i - 1]
            );
        }

        emit Withdraw(msg.sender, shares);
    }

    function emergencyWithdraw(uint256 amount) public onlyOwner {
        address owner_ = owner();
        payable(owner_).transfer(address(this).balance);
        genartToken.transfer(owner_, amount);
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

    function getMembershipsOf(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[user].membershipIds;
    }
}
