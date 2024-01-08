// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IKeeperCompatible {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}
