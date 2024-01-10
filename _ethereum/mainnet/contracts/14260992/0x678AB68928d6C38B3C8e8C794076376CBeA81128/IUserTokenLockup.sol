// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Interface of the IUserTokenLockup standard
interface IUserTokenLockup {
    /// @notice Tokens locked amount
    /// @return totalTokensLocked
    function totalTokensLocked() external view returns (uint256);
}
