// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ILoftzStylesV1 {
    // =============================================================
    // Data Structures
    // =============================================================

    // =============================================================
    // Errors
    // =============================================================

    // =============================================================
    // Events
    // =============================================================

    // =============================================================
    // Main Token Logic
    // =============================================================

    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) external;

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external;

    // =============================================================
    // Off-chain Indexing Tools
    // =============================================================

    function getBalancesOf(address _owner, uint256[] memory _ids) external view returns (uint256[] memory);
}
