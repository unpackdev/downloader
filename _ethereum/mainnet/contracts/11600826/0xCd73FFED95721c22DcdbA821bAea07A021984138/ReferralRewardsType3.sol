pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ReferralRewardsV2.sol";

contract ReferralRewardsType3 is ReferralRewardsV2 {
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
}
