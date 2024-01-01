// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;


/// @title Contract supporting versioning using SemVer version scheme.
interface IVersioned {
    /// @notice Contract version, using SemVer version scheme.
    function VERSION() external view returns (string memory);
}
