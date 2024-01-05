pragma solidity 0.5.16;

import "./ERC20.sol";

interface IFarmingRewardsV2 {
    function balanceOf(address account) external view returns (uint256);
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function exit() external;
    function getAllRewards() external;
}
