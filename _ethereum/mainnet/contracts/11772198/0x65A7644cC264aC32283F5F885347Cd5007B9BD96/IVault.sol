pragma solidity ^0.6.0;

interface IVault {
    struct UserInfo {
        uint256 amount;
        uint256 ZZZRewardDebt;
        uint256 NAPRewardDebt;
        uint256 timelockEnd;
        uint256 timelockBoost;
        mapping(uint256 => uint256) boost;
    }

    function isTimelocked(uint256 _pid, address _user) external view returns (bool);

    function getUserAmount(address _user, uint256 _vid) external view returns (uint256);
}
