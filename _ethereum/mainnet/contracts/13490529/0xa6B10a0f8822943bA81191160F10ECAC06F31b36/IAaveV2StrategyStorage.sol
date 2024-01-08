// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IAaveV2StrategyStorage {
    function stakedToken() external view returns (address);

    function lendingPool() external view returns (address);

    function incentivesController() external view returns (address);
}
