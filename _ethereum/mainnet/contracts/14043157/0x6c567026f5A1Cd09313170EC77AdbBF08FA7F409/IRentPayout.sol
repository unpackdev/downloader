// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRentPayout {

    /// @notice Emitted once Rent has been claimed for a given asset Id
    event ClaimRentFee(
        uint256 indexed _assetId,
        address indexed _token,
        address indexed _recipient,
        uint256 _amount
    );
}
