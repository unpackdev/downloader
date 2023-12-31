// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.9;

/// @title IStakingForClaims
/// @author jason@unrealaccelerator.io
/// @notice Interface for getting count of claims

interface IStakingForClaims {
    function balanceOf(address account) external view returns (uint256);
}
