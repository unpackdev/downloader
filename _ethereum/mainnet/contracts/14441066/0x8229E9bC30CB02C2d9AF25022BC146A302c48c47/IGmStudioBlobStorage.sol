// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 GmDAO
pragma solidity >=0.8.0 <0.9.0;

import "./IERC165.sol";

/// @notice Interface for on-chain data storage
interface IGmStudioBlobStorage is IERC165 {
    /// @notice Returns the stored code blob
    /// @dev Conforming to (a slice of) a GZip'ed tarball.
    function getBlob() external view returns (bytes memory);
}
