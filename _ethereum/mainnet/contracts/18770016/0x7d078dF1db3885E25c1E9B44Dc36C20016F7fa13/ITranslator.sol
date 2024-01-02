// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAsterizmEnv.sol";

/// Translator interface
interface ITranslator is IAsterizmEnv {

    /// Send transfer payload
    /// @param _dto TrSendMessageRequestDto  Method DTO
    function sendMessage(TrSendMessageRequestDto calldata _dto) external payable;

    /// Log external transfer payload
    /// @param _externalRelayAddress address  External relay address
    /// @param _dto TrSendMessageRequestDto  Method DTO
    function logExternalMessage(address _externalRelayAddress, TrSendMessageRequestDto calldata _dto) external payable;

    /// Resend failed by fee amount transfer
    /// @param _transferHash bytes32  Transfer hash
    /// @param _senderAddress uint  Sender address
    function resendMessage(bytes32 _transferHash, uint _senderAddress) external payable;

    /// Return local chain id
    /// @return uint64
    function getLocalChainId() external view returns(uint64);

    /// Return chain type by id
    /// @param _chainId  Chain id
    /// @return uint8  Chain type
    function getChainType(uint64 _chainId) external view returns(uint8);

    /// Return fee amount in tokens
    /// @param _dto TrSendMessageRequestDto  Method DTO
    /// @return uint  Token fee amount
    function getFeeAmountInTokens(TrSendMessageRequestDto calldata _dto) external view returns(uint);
}
