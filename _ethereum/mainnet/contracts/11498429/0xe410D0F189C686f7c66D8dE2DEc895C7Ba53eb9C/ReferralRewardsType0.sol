pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ReferralRewards.sol";

contract ReferralRewardsType0 is ReferralRewards {
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
}
