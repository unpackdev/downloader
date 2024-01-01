// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStrategy {
    function canStartAuction() external view returns (bool);

    function canStopAuction() external view returns (bool);

    function checkStateAfterRebalance() external view returns (bool);

    function saveState() external;
}
