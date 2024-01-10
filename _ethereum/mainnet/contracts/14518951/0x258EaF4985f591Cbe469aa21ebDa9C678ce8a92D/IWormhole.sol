// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Structs.sol";

interface IWormhole is Structs {
    function publishMessage(uint32 nonce, bytes calldata payload, uint8 consistencyLevel) external returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);
}
