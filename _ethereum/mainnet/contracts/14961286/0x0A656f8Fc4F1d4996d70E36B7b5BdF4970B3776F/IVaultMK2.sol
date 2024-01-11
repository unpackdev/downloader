// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.10;

interface IVaultMK2 {
    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function strategyHarvest(uint256 index) external returns (bool);

    function investTrigger() external view returns (bool);

    function invest() external;
}
