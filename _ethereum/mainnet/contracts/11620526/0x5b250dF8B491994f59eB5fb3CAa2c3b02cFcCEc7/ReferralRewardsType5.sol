pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ReferralRewardsV2.sol";

contract ReferralRewardsType5 is ReferralRewardsV2 {
    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _referralTree Contract with referral's tree.
    /// @param _rewards Old farming contract.
    /// @param _rewardsV2 Main farming contract.
    /// @param _depositBounds Limits of referral's stake used to determine the referral rate.
    /// @param _depositRate Referral rates based on referral's deplth and stake received from deposit.
    /// @param _stakingRate Referral rates based on referral's deplth and stake received from staking.
    constructor(
        IMintableBurnableERC20 _token,
        IReferralTree _referralTree,
        IRewards _rewards,
        IRewardsV2 _rewardsV2,
        uint256[amtLevels] memory _depositBounds,
        uint256[referDepth][amtLevels] memory _depositRate,
        uint256[referDepth][amtLevels] memory _stakingRate
    )
        public
        ReferralRewardsV2(
            _token,
            _referralTree,
            _rewards,
            _rewardsV2,
            _depositBounds,
            _depositRate,
            _stakingRate
        )
    {}

    /// @dev Allows the main farming contract to assess referral deposit rewardsV2.
    /// @param _referrer Address of the referred user.
    /// @param _referral Address of the user.
    /// @param _amount Amount of new deposit.
    function proccessDeposit(
        address _referrer,
        address _referral,
        uint256 _amount
    ) external override {
        require(
            msg.sender == address(rewardsV2),
            "assessReferalDepositReward: bad role"
        );
        referralTree.setReferral(_referrer, _referral);
        referralReward[_referrer].totalDeposit = referralReward[_referrer]
            .totalDeposit
            .add(_amount);
        address[] memory referrals =
            referralTree.getReferrals(_referrer, referDepth);
        for (uint256 i = 0; i < referrals.length; i++) {
            if (referrals[i] == address(0)) {
                continue;
            }
            accumulateReward(referrals[i]);
            ReferralInfo storage referralInfo = referralReward[referrals[i]];
            referralInfo.amounts[i] = referralInfo.amounts[i].add(_amount);
        }
    }
}
