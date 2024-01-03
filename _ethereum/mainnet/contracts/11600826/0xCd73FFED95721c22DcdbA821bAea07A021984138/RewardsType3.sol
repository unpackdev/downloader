pragma solidity ^0.6.0;

import "./RewardsV2.sol";
import "./ReferralRewardsType3.sol";

contract RewardsType3 is RewardsV2 {
    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _rewards Old main farming contract.
    /// @param _referralTree Contract with referral's tree.
    constructor(
        IMintableBurnableERC20 _token,
        IRewards _rewards,
        IReferralTree _referralTree
    ) public RewardsV2(_token, 300 days, 115740741 * 1e3) {
        ReferralRewardsType3 newRreferralRewards =
            new ReferralRewardsType3(
                _token,
                _referralTree,
                _rewards,
                IRewardsV2(address(this)),
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
        newRreferralRewards.transferOwnership(_msgSender());
        referralRewards = IReferralRewardsV2(address(newRreferralRewards));
    }
}
