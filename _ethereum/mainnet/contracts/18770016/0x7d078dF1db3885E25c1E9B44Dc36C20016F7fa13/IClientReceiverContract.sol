// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAsterizmEnv.sol";

interface IClientReceiverContract is IAsterizmEnv {

    /// Receive payload from initializer
    /// @param _dto IzAsterizmReceiveRequestDto  Method DTO
    function asterizmIzReceive(IzAsterizmReceiveRequestDto calldata _dto) external;

    /// Receive payload from client server
    /// @param _srcChainId uint64  Source chain ID
    /// @param _srcAddress uint  Source address
    /// @param _txId uint  Transaction ID
    /// @param _transferHash bytes32  Transfer hash
    /// @param _payload bytes  Payload
    function asterizmClReceive(uint64 _srcChainId, uint _srcAddress, uint _txId, bytes32 _transferHash, bytes calldata _payload) external;

    /// Transfer sending result notification
    /// @param _transferHash bytes32  Transfer hash
    /// @param _statusCode uint8  Status code
    function transferSendingResultNotification(bytes32 _transferHash, uint8 _statusCode) external;
}
