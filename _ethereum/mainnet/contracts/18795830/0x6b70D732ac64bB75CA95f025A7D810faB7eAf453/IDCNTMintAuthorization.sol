// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice interface that all potential mint authorization contracts must conform to
interface IDCNTMintAuthorization {
    /// @notice function to confirm if a given mint action is authorized or not
    /// @param destination address of the recipient of the new tokens
    /// @param amount amount of tokens being requested
    /// @return bool indicating whether or not the request is authorized or not
    function authorizeMint(
        address destination,
        uint256 amount
    ) external returns (bool);
}
