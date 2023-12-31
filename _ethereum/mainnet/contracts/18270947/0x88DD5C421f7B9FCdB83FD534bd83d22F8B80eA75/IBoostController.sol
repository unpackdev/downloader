// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IBoostController {
    function getBoostAmount(uint256 _amount, uint64 _lockingDuration) external view returns (uint256);
}
