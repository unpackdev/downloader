pragma solidity ^0.6.0;

import "./Rewards.sol";
import "./ReferralRewardsType1.sol";

contract RewardsType1 is Rewards {
    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _referralTree Contract with referral's tree.
    constructor(dANT _token, ReferralTree _referralTree)
        public
        Rewards(_token, 150 days, 86805555556)
    {
        referralRewards = new ReferralRewardsType1(
            _token,
            _referralTree,
            Rewards(address(this)),
            [uint256(5000 * 1e18), 2000 * 1e18, 100 * 1e18],
            [
                [uint256(6 * 1e16), 2 * 1e16, 1 * 1e16],
                [uint256(5 * 1e16), 15 * 1e15, 75 * 1e14],
                [uint256(4 * 1e16), 1 * 1e16, 5 * 1e15]
            ],
            [
                [uint256(6 * 1e16), 2 * 1e16, 1 * 1e16],
                [uint256(5 * 1e16), 15 * 1e15, 75 * 1e14],
                [uint256(4 * 1e16), 1 * 1e16, 5 * 1e15]
            ]
        );
        referralRewards.transferOwnership(_msgSender());
    }
}
