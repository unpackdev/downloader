pragma solidity 0.8.19;
import "./IERC20.sol";

interface IScrambleChef {
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount, address _account) external;
    function withdraw(uint256 _pid, uint256 _amount, address _account) external;
    function claim(uint256 _pid, address _account) external returns (uint256);
    function queueRewards(address _account) external;
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;
    function updateRewardPerSecond(uint256 _rewardPerSecond) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256, uint256);
    function totalAllocPoint() external view returns (uint256);
    function totalStakedInPool(uint256 _pid) external view returns (uint256);
    function userRewards(uint256 _pid, address _user) external view returns (uint256);
    function lastTimestamp() external view returns (uint256);
    function lockDurations(uint256 _pid) external view returns (uint256);
    function rewardPerSecond() external view returns (uint256);
    function add(uint, IERC20, bool) external;
}