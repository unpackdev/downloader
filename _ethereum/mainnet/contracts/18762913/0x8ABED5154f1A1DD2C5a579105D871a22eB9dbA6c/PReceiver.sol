// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IPReceiver.sol";

abstract contract PReceiver is IPReceiver {
    /// @inheritdoc IPReceiver
    function receiveUserData(
        bytes4 originNetworkId,
        string calldata originAccount,
        bytes calldata userData
    ) external virtual {}
}
