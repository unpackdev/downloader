pragma solidity >=0.5.0 <0.9.0;

interface IConvexBaseRewardPool {
    // Views

    function rewards(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    // Mutative

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function stake(uint256 _amount) external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external returns (bool);
}