// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

interface ICreatureRewards is IERC165Upgradeable {
    event EnergyUpdated(address indexed user, bool increase, uint energy, uint timestamp);
    event StakedTransfer(address indexed from, address to, uint indexed tokenId, uint energy);

    event RewardsSet(uint32 start, uint32 end, uint256 rate);
    event RewardsPerEnergyUpdated(uint256 accumulated);
    event UserRewardsUpdated(address user, uint256 userRewards, uint256 paidRewardPerEnergy);
    event RewardClaimed(address receiver, uint256 claimed);

    function stakedEnergy(address user) external view returns(uint);
    function getRewardRate() external view returns(uint);
    function checkUserRewards(address user) external view returns(uint);
    function version() external view returns(string memory);

    function alertStaked(address user, uint tokenId, bool staked, uint energy) external;
    function alertBoost(address user, uint tokenId, bool boost, uint energy) external;
    function alertStakedTransfer(address from, address to, uint tokenId, uint energy) external;
    function claim(address to) external;
}