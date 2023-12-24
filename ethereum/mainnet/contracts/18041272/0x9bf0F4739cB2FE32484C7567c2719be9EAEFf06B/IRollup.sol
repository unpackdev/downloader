// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

interface IRollup {
    function isFraudulentLockId(uint256 _lockId) external view returns (bool); 
    function isConfirmedLockId(uint256 _lockId) external view returns (bool); 
    function markFraudulent(uint256 epoch) external;

    function getProposedStateRoot(uint256 epoch) external view returns (bytes32);
    function getConfirmedStateRoot(uint256 epoch) external view returns (bytes32);
    function getCurrentEpoch() external view returns (uint256);
}
