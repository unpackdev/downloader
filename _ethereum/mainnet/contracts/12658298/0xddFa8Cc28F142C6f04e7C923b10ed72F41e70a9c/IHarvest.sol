// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IHarvest {
    function setHarvestRewardVault(address _harvestRewardVault) external;

    function setHarvestRewardPool(address _harvestRewardPool) external;

    function setHarvestPoolToken(address _harvestfToken) external;

    function setFarmToken(address _farmToken) external;

    function updateReward() external;
}
