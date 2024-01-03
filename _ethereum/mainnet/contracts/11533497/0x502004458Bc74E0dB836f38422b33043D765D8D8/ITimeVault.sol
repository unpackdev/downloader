// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimeVault {
    function withdrawalSlots(uint256 slot) external view returns (uint256);
}
