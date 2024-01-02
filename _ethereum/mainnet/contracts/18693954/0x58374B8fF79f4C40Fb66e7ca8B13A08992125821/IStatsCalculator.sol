// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity 0.8.17;

/// @title Capture information about a pool or destination
interface IStatsCalculator {
    /// @notice thrown when no snapshot is taken
    error NoSnapshotTaken();

    /// @notice The id for this instance of a calculator
    function getAprId() external view returns (bytes32);

    /// @notice The id of the underlying asset/pool/destination this calculator represents
    /// @dev This may be a generated address
    function getAddressId() external view returns (address);

    /// @notice Setup the calculator after it has been copied
    /// @dev Should only be executed one time
    /// @param dependentAprIds apr ids that cover the dependencies of this calculator
    /// @param initData setup data specific to this type of calculator
    function initialize(bytes32[] calldata dependentAprIds, bytes calldata initData) external;

    /// @notice Capture stat data about this setup
    function snapshot() external;

    /// @notice Indicates if a snapshot should be taken
    /// @return takeSnapshot if true then a snapshot should be taken. If false, calling snapshot will do nothing
    function shouldSnapshot() external view returns (bool takeSnapshot);
}
