pragma solidity >=0.6.6;

interface IReward {
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function balanceOf(address user) external view returns (uint);
}
