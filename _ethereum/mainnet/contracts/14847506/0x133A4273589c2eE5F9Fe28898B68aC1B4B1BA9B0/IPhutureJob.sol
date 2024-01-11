// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./ValidatorLibrary.sol";

import "./IOrderer.sol";

/// @title Phuture job interface
/// @notice Contains signature verification and order execution logic
interface IPhutureJob {
    /// @notice Pause order execution
    function pause() external;

    /// @notice Unpause order execution
    function unpause() external;

    /// @notice Sets minimum amount of signers required to sign a job
    /// @param _minAmountOfSigners Minimum amount of signers required to sign a job
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external;

    /// @notice Reweights given index
    /// @param _index Index to reweight
    function reweight(address _index) external;

    /// @notice Swap shares internally
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrderer.InternalSwap calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrderer.ExternalSwap calldata _info) external;

    /// @notice Swap shares internally (manual)
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function internalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrderer.InternalSwap calldata _info) external;

    /// @notice Swap shares using DEX (manual)
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function externalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrderer.ExternalSwap calldata _info) external;

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice Nonce of signer
    /// @param _signer Signer address
    /// @return Returns nonce of given signer
    function nonces(address _signer) external view returns (uint256);

    /// @notice Minimum amount of signers required to sign a job
    /// @return Returns minimum amount of signers required to sign a job
    function minAmountOfSigners() external view returns (uint256);
}
