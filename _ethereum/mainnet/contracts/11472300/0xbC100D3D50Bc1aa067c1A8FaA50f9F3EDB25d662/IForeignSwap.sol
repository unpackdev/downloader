// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IForeignSwap {
    function getCurrentClaimedAmount() external view returns (uint256);

    function getTotalSnapshotAmount() external view returns (uint256);

    function getCurrentClaimedAddresses() external view returns (uint256);

    function getTotalSnapshotAddresses() external view returns (uint256);
}
