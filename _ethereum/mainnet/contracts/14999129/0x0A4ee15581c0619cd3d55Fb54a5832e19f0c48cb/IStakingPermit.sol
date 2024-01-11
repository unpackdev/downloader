// SPDX-License-Identifier: AGPL-3.0-only
// ERC20 Extensions v1.1.1
pragma solidity ^0.8.0;

/// @notice see Staking.sol
/// @dev adds support for depositing tokens with permit if underlying token supports EIP2612
interface IStakingPermit {
    /// @notice allows to deposit tokens without an approve transaction by using the EIP2612 permit standard
    /// @param amount amount of underlying token to deposit
    /// @param deadline until the signature is valid
    /// @param signature permit signature
    /// @return amount of overlying tokens received
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256);
}
