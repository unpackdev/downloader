// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IFarmActivator {
    function startFarming(address _rewardToken, address _farmToken) external;
}
