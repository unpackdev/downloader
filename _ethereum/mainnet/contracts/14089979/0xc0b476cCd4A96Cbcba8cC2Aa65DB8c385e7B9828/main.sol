// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./events.sol";
import "./helpers.sol";

contract InteropBetaResolver is Events, Helpers {
    constructor(address interop) Helpers(interop) {}

    function submitAction(
        Position memory position,
        string memory actionId,
        uint256 targetDsaId,
        uint256 targetChainId,
        bytes memory metadata
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        _submitAction(
            position,
            actionId,
            uint64(targetDsaId),
            targetChainId,
            metadata
        );

        _eventName = "LogSourceMagic(Position,address,string,uint256,uint256,bytes)";
        _eventParam = abi.encode(position, msg.sender, actionId, targetDsaId, targetChainId, metadata);
    }

    function submitActionERC20(
        Position memory position,
        string memory actionId,
        uint256 targetDsaId,
        uint256 targetChainId,
        bytes memory metadata
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        _submitActionERC20(
            position,
            actionId,
            uint64(targetDsaId),
            targetChainId,
            metadata
        );

        _eventName = "LogSourceMagic(Position,address,string,uint256,uint256,bytes)";
        _eventParam = abi.encode(position, msg.sender, actionId, targetDsaId, targetChainId, metadata);
    }
}

contract ConnectV2Interop is InteropBetaResolver {
    constructor(address interop) InteropBetaResolver(interop) {}

    string public constant name = "Interop-v1.1";
}
