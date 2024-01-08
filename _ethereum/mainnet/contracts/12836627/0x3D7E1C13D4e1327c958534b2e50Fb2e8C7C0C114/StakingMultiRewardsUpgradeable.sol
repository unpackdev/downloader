// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./console.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./MathUpgradeable.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./StorageV1ConsumerUpgradeable.sol";

// Inheritance
import "./IStakingMultiRewards.sol";
import "./ISelfCompoundingYield.sol";

/// Multi-reward staking pool. This reward is used for dsitributing the longAsset from the vault.
/// This is a generalized version of the staking pool from synthetix. Additionally, users of 
/// the vault does not need to manually "stake" into this reward pool. They are automatically 
/// staked when they hold the vault tokens. 
///
/// See also: https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingMultiRewardsUpgradeable is
    IStakingMultiRewards,
    StorageV1ConsumerUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct Yield {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 duration;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
        bool isSelfCompoudingYield;
    }

    /* ========== STATE VARIABLES ========== */
    /// Address of vault associated with this reward pool.
    address public vaultAddress;
    mapping (address => bool) rewardsDistribution;
    mapping(address => Yield) public yieldInfo;
    EnumerableSetUpgradeable.AddressSet yields;

    modifier onlyRewardsDistribution() {
        require(
            rewardsDistribution[msg.sender],
            "Caller is not RewardsDistribution"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _store,
        address _rewardsDistribution,
        address _vaultAddress,
        address _yieldToken,
        uint256 _yieldDuration,
        bool _isSelfCompounding
    ) public initializer {
        super.initialize(_store);
        rewardsDistribution[_rewardsDistribution] = true;
        rewardsDistribution[_vaultAddress] = true;
        vaultAddress = _vaultAddress;

        yields.add(_yieldToken);
        yieldInfo[_yieldToken].duration = _yieldDuration;
        yieldInfo[_yieldToken].isSelfCompoudingYield = _isSelfCompounding;        
    }

    // /* ========== VIEWS ========== */
    /**
        Reward Distribution
    */

    function setRewardDistribution(address[] calldata _rewardDistributions, bool _flag) external override adminPriviledged {
        for(uint256 i = 0 ; i < _rewardDistributions.length; i++) {
            rewardsDistribution[_rewardDistributions[i]] = _flag;
        }
    }

    function notifyTargetRewardAmount(address targetYield, uint256 reward) external override onlyRewardsDistribution {
        // https://sips.synthetix.io/sips/sip-77
        require(reward < uint(-1) / 1e18, "the notified reward cannot invoke multiplication overflow");
        require(yields.contains(targetYield), "yield token doesn't exist.");

        Yield storage yinfo = yieldInfo[targetYield];

        if (block.timestamp >= yinfo.periodFinish) {
            yinfo.rewardRate = reward.div(yinfo.duration);
        } else {
            uint256 remainingTime = yinfo.periodFinish.sub(block.timestamp);
            uint256 leftover = remainingTime.mul(yinfo.rewardRate);
            yinfo.rewardRate = reward.add(leftover).div(yinfo.duration);
            yinfo.rewardRate = reward.add(leftover).div(yinfo.duration);
        }
        yinfo.lastUpdateTime = block.timestamp;
        yinfo.periodFinish = block.timestamp.add(yinfo.duration);
        emit RewardNotified(targetYield, reward);
    }

    /*
        handling the original ERC20 functions
    */

    function totalSupply() public view override returns(uint256) {
        return (IERC20Upgradeable(vaultAddress).totalSupply());
    }

    function updateAllRewards(address targetAccount) public override {
        for(uint256 i = 0 ; i < yields.length(); i++) {
            updateReward(yields.at(i), targetAccount);
        }
    }

    function updateReward(address targetYield, address targetAccount) public override {
        Yield storage yinfo = yieldInfo[targetYield];

        yinfo.rewardPerTokenStored = rewardPerToken(targetYield);
        yinfo.lastUpdateTime = lastTimeRewardApplicable(targetYield);

        if(targetAccount != address(0)) {
            yinfo.rewards[targetAccount] = earned(targetYield, targetAccount);
            yinfo.userRewardPerTokenPaid[targetAccount] = yinfo.rewardPerTokenStored;
        }
    }

    /*
        Reward calculation
    */
    function lastTimeRewardApplicable(address targetYield) public view override returns (uint256) {
        Yield storage yinfo = yieldInfo[targetYield];
        return MathUpgradeable.min(block.timestamp, yinfo.periodFinish);
    }

    function rewardPerToken(address targetYield) public view override returns (uint256) {
        Yield storage yinfo = yieldInfo[targetYield];

        if (totalSupply() == 0) {
            return yinfo.rewardPerTokenStored;
        }
        return
        (yinfo.rewardPerTokenStored).add(
            lastTimeRewardApplicable(targetYield)
            .sub(yinfo.lastUpdateTime)
            .mul(yinfo.rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }

    /*
        Detect whether the yield is wrapped. If it is, calculate the unwrapped amount for the user
    */
    /// Calculate the amount of reward token earned by a user.
    /// If the reward token is the share of a self-compounding vault, calculate the reward as the underlying bassetAsset.
    /// @param targetYield Address of the reward token.
    /// @param account Address of the user account
    /// @return Return the amount of reward token earned (as the baseAsset if the targetYield is a self-compound vault.).
    function earnedUnwrapped(address targetYield, address account) public view returns(uint256) {
        Yield storage yinfo = yieldInfo[targetYield];
        uint256 amount = earned(targetYield, account);
        if(yinfo.isSelfCompoudingYield) {
            amount = ISelfCompoundingYield(targetYield).shareToBaseAsset(amount);
        }
        return amount;
    }

    /// Calculate the amount of reward token earned by a user
    /// @param targetYield Address of the reward token.
    /// @param account Address of the user account
    /// @return Return the amount of reward token earned.
    function earned(address targetYield, address account) public view override returns(uint256) {
        Yield storage yinfo = yieldInfo[targetYield];
        return
            IERC20Upgradeable(vaultAddress).balanceOf(account)
            .mul(rewardPerToken(targetYield).sub(yinfo.userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(yinfo.rewards[account]);
    }

    /// Claim all the rewards. See getRewardFor for details.
    function getAllRewards() public override {
        for(uint256 i = 0; i < yields.length(); i++) {
            getReward(yields.at(i));
        }
    }

    /// Claim all the rewards for a user. See getRewardFor for details.
    /// @param user Address of the user.
    function getAllRewardsFor(address user) public override{
        for(uint256 i = 0; i < yields.length(); i++) {
            getRewardFor(user, yields.at(i));
        }
    }

    /// Claim the reward. See getRewardFor for details.
    /// @param targetYield The address of the reward.
    function getReward(address targetYield) public override {
        _getReward(msg.sender, targetYield);
    }

    /// Claim the reward for a user. 
    /// If the reward is the share of self-compound asset, baseAsset of the vault would be withdrawed and sent to the user.
    /// @param targetYield The address of the reward.
    /// @param user Address of the user.
    function getRewardFor(address user, address targetYield) public override {
        _getReward(user, targetYield);
    }

    function _getReward(address user, address targetYield) internal {
        updateReward(targetYield, user);
        uint256 gained = earned(targetYield, user);
        Yield storage yinfo = yieldInfo[targetYield];
        if(gained > 0 && IERC20Upgradeable(targetYield).balanceOf(address(this)) >= gained) {
            yinfo.rewards[user] = 0;
            if(yinfo.isSelfCompoudingYield) {                
                // `gained` is how much the user earned in wrapped amount, 
                // thus we unwrap it here and send the unwrapped yield to the user.
                address baseAssetAddress = ISelfCompoundingYield(targetYield).baseAsset();
                uint256 beforeBaseAmount = IERC20Upgradeable(baseAssetAddress).balanceOf(address(this));
                ISelfCompoundingYield(targetYield).withdraw(gained);
                uint256 afterBaseAmount = IERC20Upgradeable(baseAssetAddress).balanceOf(address(this));
                uint256 receivedAmount = afterBaseAmount.sub(beforeBaseAmount);
                
                IERC20Upgradeable(baseAssetAddress).safeTransfer(user, receivedAmount);
                emit RewardPayOut(baseAssetAddress, receivedAmount, user);
            } else {
                IERC20Upgradeable(targetYield).safeTransfer(user, gained);
                emit RewardPayOut(targetYield, gained, user);
            }
        }
    }

    /// Add a new reward to the reward pool.
    /// @param targetYield Address of the new reward token.
    /// @param duration Reward distribution duration.
    /// @param isSelfCompoundingYield If the new reward is the share of a self-compounding vault.
    function addReward(address targetYield, uint256 duration, bool isSelfCompoundingYield) external adminPriviledged override {
        require(!yields.contains(targetYield), "Token is already in the set");
        Yield storage yinfo = yieldInfo[targetYield];
        yinfo.duration = duration;
        yinfo.isSelfCompoudingYield = isSelfCompoundingYield;
        yields.add(targetYield);
        emit RewardAdded(targetYield);
    }

    function removeReward(address targetYield) external adminPriviledged override {
        require(yields.contains(targetYield), "Token is not in the set");
        Yield storage yinfo = yieldInfo[targetYield];
        require(yinfo.periodFinish < block.timestamp, "still distributing, cannot remove");
        require(yields.length() > 1, "Cannot remove the last yield");
        yields.remove(targetYield);
        emit RewardRemoved(targetYield);
    }

    /* ========== EVENTS ========== */

    event RewardNotified(address targetYield, uint256 amount);
    event RewardAdded(address targetYield);
    event RewardRemoved(address targetYield);
    event RewardPaid(address indexed user, address targetYield, uint256 reward);
    event RewardsDurationUpdated(address targetYield, uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event RewardPayOut(address targetYield, uint256 gained, address to);
}
