pragma solidity >=0.4.24;


interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable(uint256 _id) external view returns (uint256);

    function rewardPerToken(uint256 _id) external view returns (uint256);

    function earned(uint256 _id, address account) external view returns (uint256);

    function getRewardForDuration(uint256 _id) external view returns (uint256);

    function totalSupply(uint256 _id) external view returns (uint256);

    function balanceOf(uint256 _id, address account) external view returns (uint256);

    // Mutative

    function stake(uint256 _id, uint256 amount) external;

    function withdraw(uint256 _id, uint256 amount) external;

    function getReward(uint256 _id) external;
    
    function initPool(uint256 _id) external;
}
