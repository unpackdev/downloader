// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IReceiver.sol";

interface IMessageTransmitter is IReceiver {
    function usedNonces(bytes32 _sourceAndNonce) external view returns (uint256);
}
