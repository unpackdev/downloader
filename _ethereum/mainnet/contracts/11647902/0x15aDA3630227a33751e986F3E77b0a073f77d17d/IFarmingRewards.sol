pragma solidity 0.5.16;

import "./ERC20.sol";

interface IFarmingRewards {
    function balanceOf(address account) external view returns (uint256);
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function exit() external;
    function getReward() external;
}
