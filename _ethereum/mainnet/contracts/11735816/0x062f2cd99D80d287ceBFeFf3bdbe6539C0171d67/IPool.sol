pragma solidity ^0.6.0;

interface IPool {
    function stake(address account, uint256 amount) external;
    function withdraw(address account, uint256 amount) external;
    function notifyRewardAmount(uint256 reward) external;
}
