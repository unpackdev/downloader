pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OpenEndedRewardManager.sol";
import "./IFestakeRewardManager.sol";
import "./IFestakeWithdrawer.sol";
import "./Constants.sol";

/**
 * Reward continuation can be used to add reward to any staking.
 * We cannot withdraw or stake from here, but we can withdrawRewards.
 * Key is to do a shaddow management of stakes on this contract.
 */
contract FestakedRewardContinuation is OpenEndedRewardManager {
    IFestaked public targetStake;
    bool initialSync = false;
    constructor(
        address targetStake_,
        address tokenAddress_,
        address rewardTokenAddress_) OpenEndedRewardManager(
            "RewardContinuation", tokenAddress_, rewardTokenAddress_, now, Constants.Future2100,
            Constants.Future2100+1, Constants.Future2100+2, 2**128) public {
            targetStake = IFestaked(targetStake_);
    }

    function initialize() public virtual returns (bool) {
        require(!initialSync, "FRC: Already initialized");
        require(now >= targetStake.stakingEnds(), 
            "FRC: Bad timing. Cannot initialize before target stake contribution is closed");
        uint256 stakedBalance_ = targetStake.stakedBalance();
        stakedTotal = stakedBalance_;
        stakedBalance = stakedBalance_;
        initialSync = true;
        return true;
    }

    /**
     * @dev Checks the current stake against the original.
     * runs a dummy withdraw or stake then calculates the rewards accordingly.
     */
    function rewardOf(address staker)
    external override view returns (uint256) {
        require(initialSync, "FRC: Run initialSync");
        if (_stakes[staker] == 0) {
            uint256 remoteStake = _remoteStake(staker);
            return _calcRewardOf(staker, stakedBalance, remoteStake);
        }
        return _calcRewardOf(staker, stakedBalance, _stakes[staker]);
    }

    function _stake(address, address, uint256)
    override
    virtual
    internal
    returns (bool)
    {
        require(false, "RewardContinuation: Stake not supported");
    }

    function withdraw(uint256) external override virtual returns (bool) {
        require(false, "RewardContinuation: Withdraw not supported");
    }

    function _addMarginalReward()
    internal override virtual returns (bool) {
        address me = address(this);
        IERC20 _rewardToken = rewardToken;
        uint256 amount = _rewardToken.balanceOf(me).sub(rewardsTotal);
        // We don't carry stakes here
        // if (address(_rewardToken) == tokenAddress) {
        //     amount = amount.sub(...);
        // }
        if (amount == 0) {
            return true; // No reward to add. Its ok. No need to fail callers.
        }
        rewardsTotal = rewardsTotal.add(amount);
        fakeRewardsTotal = fakeRewardsTotal.add(amount);
    }

    function withdrawRewardsFor(address staker) external returns (uint256) {
        require(msg.sender != address(0), "OERM: Bad address");
        return _withdrawRewardsForRemote(staker);
    }

    function withdrawRewards() external override returns (uint256) {
        require(msg.sender != address(0), "OERM: Bad address");
        return _withdrawRewardsForRemote(msg.sender);
    }

    /**
     * @dev it is important to know there will be no more stake on the remote side
     */
    function _withdrawRewardsForRemote(address staker) internal returns(uint256) {
        require(initialSync, "FRC: Run initialSync");
        uint256 currentStake = Festaked._stakes[staker];
        uint256 remoteStake = _remoteStake(staker);
        uint256 stakedBalance_ = targetStake.stakedBalance();
        // Make sure total staked hasnt gone up on the other side.
        require(stakedBalance_ <= stakedTotal, "FRC: Remote side staked total has increased!");
        require(currentStake == 0 || remoteStake <= currentStake, "FRC: Cannot stake more on the remote side");
        if (currentStake == 0) {
            // First time. Replicate the stake.
            _stakes[staker] = remoteStake;
            _withdrawRewards(staker);
        } else if (remoteStake < currentStake) {
            // This means user has withdrawn remotely! Run the withdraw here to match remote.
            uint256 amount = currentStake.sub(remoteStake);
            _withdraw(staker, amount);
            require(_stakes[staker] == remoteStake, "FRC: Wirhdraw simulation didn't happen correctly!");
        } else {
            _withdrawRewards(staker);
        }
    }

    function _withdraw(address _staker, uint256 amount)
    internal override virtual returns (bool) {
        uint256 actualPay = _withdrawOnlyUpdateState(_staker, amount);
        // We do not have main token to pay. This is just a simulation of withdraw
        // IERC20(tokenAddress).safeTransfer(_staker, amount);
        if (actualPay != 0) {
            rewardToken.safeTransfer(_staker, actualPay);
        }
        emit PaidOut(tokenAddress, address(rewardToken), _staker, 0, actualPay);
        return true;
    }

    function _remoteStake(address staker) internal view returns (uint256){
        return targetStake.stakeOf(staker);
    }
}