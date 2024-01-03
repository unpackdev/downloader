pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ReferralRewards.sol";

contract ReferralRewardsType2 is ReferralRewards {
    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _referralTree Contract with referral's tree.
    /// @param _rewards Main farming contract.
    /// @param _depositBounds Limits of referral's stake used to determine the referral rate.
    /// @param _depositRate Referral rates based on referral's deplth and stake received from deposit.
    /// @param _stakingRate Referral rates based on referral's deplth and stake received from staking.
    constructor(
        dANT _token,
        ReferralTree _referralTree,
        Rewards _rewards,
        uint256[amtLevels] memory _depositBounds,
        uint256[referDepth][amtLevels] memory _depositRate,
        uint256[referDepth][amtLevels] memory _stakingRate
    )
        public
        ReferralRewards(
            _token,
            _referralTree,
            _rewards,
            _depositBounds,
            _depositRate,
            _stakingRate
        )
    {}

    /// @dev Allows the main farming contract to assess referral deposit rewards.
    /// @param _referrer Address of the referred user.
    /// @param _amount Amount of new deposit.
    function assessReferalDepositReward(address _referrer, uint256 _amount)
        external
        override
    {
        require(
            msg.sender == address(rewards),
            "assessReferalDepositReward: bad role"
        );
        address[] memory referrals = referralTree.getReferrals(
            _referrer,
            referDepth
        );
        for (uint256 i = 0; i < referrals.length; i++) {
            if (referrals[i] == address(0)) {
                continue;
            }
            accumulateReward(referrals[i]);
            ReferralInfo storage referralInfo = referralReward[referrals[i]];
            referralInfo.deposits[referralInfo.depositTail] = DepositInfo({
                referrer: _referrer,
                depth: i,
                amount: _amount,
                lastUpdatedTime: now,
                time: 0
            });
            referralInfo.amounts[i] = referralInfo.amounts[i].add(_amount);
            referralInfo.depositTail = referralInfo.depositTail.add(1);
        }
    }

    /// @dev Update the staking referral reward for _user.
    /// @param _user Address of the referral.
    function accumulateReward(address _user) internal override {
        ReferralInfo storage referralInfo = referralReward[_user];
        if (referralInfo.lastUpdate >= now) {
            return;
        }
        uint256 rewardPerSec = rewards.rewardPerSec();
        uint256 referralStake = rewards.getReferralStake(_user);
        uint256[referDepth] memory rates = getStakingRateRange(referralStake);
        if (referralInfo.lastUpdate > 0) {
            for (uint256 i = 0; i < referralInfo.amounts.length; i++) {
                uint256 reward = now
                    .sub(referralInfo.lastUpdate)
                    .mul(referralInfo.amounts[i])
                    .mul(rewardPerSec)
                    .mul(rates[i])
                    .div(1e18);
                if (reward > 0) {
                    referralInfo.reward = referralInfo.reward.add(reward);
                }
            }
        }
        referralInfo.lastUpdate = now;
    }

    /// @dev Allows the main farming contract to decrement staked amount that generates reward to the referrals.
    /// @param _referrer Address of the referrer.
    /// @param _amount Ammount of tokens to be withdrawn by referrer.
    function removeDepositReward(address _referrer, uint256 _amount)
        external
        override
    {
        require(
            msg.sender == address(rewards),
            "removeDepositReward: bad role"
        );
        address[] memory referrals = referralTree.getReferrals(
            _referrer,
            referDepth
        );
        for (uint256 i = 0; i < referrals.length; i++) {
            if (referrals[i] == address(0)) {
                continue;
            }
            accumulateReward(referrals[i]);
            ReferralInfo storage referralInfo = referralReward[referrals[i]];
            referralInfo.amounts[i] = referralInfo.amounts[i].sub(_amount);
        }
    }

    /// @dev Returns referral reward.
    /// @param _user Address of referral.
    /// @return Referral reward.
    function getReferralReward(address _user)
        external
        override
        view
        returns (uint256)
    {
        ReferralInfo storage referralInfo = referralReward[_user];
        uint256 rewardPerSec = rewards.rewardPerSec();
        uint256 referralStake = rewards.getReferralStake(_user);
        uint256[referDepth] memory rates = getStakingRateRange(referralStake);
        uint256 _reward = referralInfo.reward;
        if (referralInfo.lastUpdate > 0) {
            for (uint256 i = 0; i < referralInfo.amounts.length; i++) {
                _reward = _reward.add(
                    now
                        .sub(referralInfo.lastUpdate)
                        .mul(referralInfo.amounts[i])
                        .mul(rewardPerSec)
                        .mul(rates[i])
                        .div(1e18)
                );
            }
        }
        return _reward.div(1e18);
    }
}
