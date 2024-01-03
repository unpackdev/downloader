pragma solidity ^0.6.0;

// import "./dANT.sol";
import "./IReferralRewards.sol";

interface IRewardsV2 {
    struct DepositInfo {
        uint256 amount;
        uint256 time;
    }

    struct UserInfo {
        uint256 amount;
        uint256 unfrozen;
        uint256 reward;
        uint256 lastUpdate;
        uint256 depositHead;
        uint256 depositTail;
        mapping(uint256 => DepositInfo) deposits;
    }

    function setActive(bool _isActive) external;

    function setReferralRewards(IReferralRewards _referralRewards) external;

    function setDuration(uint256 _duration) external;

    function setRewardPerSec(uint256 _rewardPerSec) external;

    function stakeFor(address _user, uint256 _amount) external;

    function stake(uint256 _amount, address _refferal) external;

    function getPendingReward(address _user, bool _includeDeposit)
        external
        view
        returns (uint256 _reward);

    function rewardPerSec() external view returns (uint256);

    function getReward(address _user) external view returns (uint256 _reward);

    function getReferralStake(address _referral)
        external
        view
        returns (uint256);

    function getEstimated(uint256 _delta) external view returns (uint256);

    function getDeposit(address _user, uint256 _id)
        external
        view
        returns (uint256, uint256);
}
