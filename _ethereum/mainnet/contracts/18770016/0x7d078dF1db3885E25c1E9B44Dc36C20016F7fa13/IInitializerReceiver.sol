// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAsterizmEnv.sol";
import "./IConfig.sol";

/// Initializer receive interface
interface IInitializerReceiver is IAsterizmEnv, IConfig {

    /// Receive payload from translator
    /// @param _dto IzReceivePayloadRequestDto  Method DTO
    function receivePayload(IzReceivePayloadRequestDto calldata _dto) external;

    /// Transfer sending result notification
    /// @param _targetAddress address  Target client contract address
    /// @param _transferHash bytes32  Transfer hash
    /// @param _statusCode uint8  Status code
    function transferSendingResultNotification(address _targetAddress, bytes32 _transferHash, uint8 _statusCode) external;
}
