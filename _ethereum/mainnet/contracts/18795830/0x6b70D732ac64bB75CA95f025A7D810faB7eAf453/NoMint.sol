// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDCNTMintAuthorization.sol";

/// @notice an implementation of IDCNTMintAuthorization that allows all mint requests
contract NoMint is IDCNTMintAuthorization {
    /// @notice simply returns true, indicating that the mint request is authorized
    function authorizeMint(address, uint256) external pure returns (bool) {
        return false;
    }
}
