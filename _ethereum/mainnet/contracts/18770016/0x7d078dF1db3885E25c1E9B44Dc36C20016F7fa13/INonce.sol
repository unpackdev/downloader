// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// Asterizm nonce interface
interface INonce {

    /// Increase nonce
    /// @param _chainId uint64  Chain ID
    /// @param _pathData bytes  Nonce data
    function increaseNonce(uint64 _chainId, bytes calldata _pathData) external returns (uint);

    /// Increase nonce with validation
    /// @param _chainId uint64  Chain ID
    /// @param _pathData bytes  Nonce data
    /// @param _nonce uint  External nonce
    function increaseNonceWithValidation(uint64 _chainId, bytes calldata _pathData, uint _nonce) external returns (uint);

    /// Return nonce
    /// @param _chainId uint64  Chain ID
    /// @param _pathData bytes  Nonce data
    function getNonce(uint64 _chainId, bytes calldata _pathData) external returns (uint);

    /// Return nonce (base logic)
    /// @param _chainId uint64  Chain ID
    /// @param _srcAddress uint  Source address
    /// @param _dstAddress uint  Destination address
    function getNonceBase(uint64 _chainId, uint _srcAddress, uint _dstAddress) external view returns (uint);
}
