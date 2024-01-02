// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAsterizmEnv.sol";

/// Initializer sender interface
interface IInitializerSender is IAsterizmEnv {

    /// Initiate asterizm transfer
    /// @param _dto IzInitTransferRequestDto  Method DTO
    function initTransfer(IzInitTransferRequestDto calldata _dto) external payable;

    /// Validate income transfer by hash
    /// @param _transferHash bytes32
    function validIncomeTransferHash(bytes32 _transferHash) external view returns(bool);

    /// Return local chain id
    /// @return uint64
    function getLocalChainId() external view returns(uint64);

    /// Return chain type by id
    /// @param _chainId  Chain id
    /// @return uint8  Chain type
    function getChainType(uint64 _chainId) external view returns(uint8);

    /// Resend failed by fee amount transfer
    /// @param _transferHash bytes32  Transfer hash
    /// @param _relay address  Relay address
    function resendTransfer(bytes32 _transferHash, address _relay) external payable;

    /// Return fee amount in tokens
    /// @param _relayAddress  Relay address
    /// @param _dto IzInitTransferV2RequestDto  Method DTO
    /// @return uint  Token fee amount
    function getFeeAmountInTokens(address _relayAddress, IzInitTransferRequestDto calldata _dto) external view returns(uint);
}
