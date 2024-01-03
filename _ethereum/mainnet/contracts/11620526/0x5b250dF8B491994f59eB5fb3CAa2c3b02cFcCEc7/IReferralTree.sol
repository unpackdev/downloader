pragma solidity ^0.6.0;

import "./IReferralRewards.sol";

interface IReferralTree {
    function changeAdmin(address _newAdmin) external;

    function setReferral(address _referrer, address _referral) external;

    function removeReferralReward(IReferralRewards _referralRewards) external;

    function addReferralReward(IReferralRewards _referralRewards) external;

    function claimAllDividends() external;

    function getReferrals(address _referrer, uint256 _referDepth)
        external
        view
        returns (address[] memory);

    function referrals(address _referrer) external view returns (address);

    function getReferrers(address _referral)
        external
        view
        returns (address[] memory);

    function getUserReferralReward(address _user)
        external
        view
        returns (uint256);

    function getReferralRewards()
        external
        view
        returns (IReferralRewards[] memory);
}
