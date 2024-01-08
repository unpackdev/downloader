pragma solidity 0.6.2;

interface IGovernanceMothership {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function notify() external;
}