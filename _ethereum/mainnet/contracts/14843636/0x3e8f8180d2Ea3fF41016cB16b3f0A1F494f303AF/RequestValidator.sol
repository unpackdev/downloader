// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// ██╗  ██╗██╗██████╗ ███████╗ ██████╗ ██╗   ██╗████████╗    ██╗      █████╗ ██████╗ ███████╗
// ██║  ██║██║██╔══██╗██╔════╝██╔═══██╗██║   ██║╚══██╔══╝    ██║     ██╔══██╗██╔══██╗██╔════╝
// ███████║██║██║  ██║█████╗  ██║   ██║██║   ██║   ██║       ██║     ███████║██████╔╝███████╗
// ██╔══██║██║██║  ██║██╔══╝  ██║   ██║██║   ██║   ██║       ██║     ██╔══██║██╔══██╗╚════██║
// ██║  ██║██║██████╔╝███████╗╚██████╔╝╚██████╔╝   ██║       ███████╗██║  ██║██████╔╝███████║
// ╚═╝  ╚═╝╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝    ╚═╝       ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
/// @title Signature Request Validator
/// @dev v1.0
/// @author hideoutlabs (https://www.twitter.com/hideoutlabs)

abstract contract RequestValidator {
    function verifySignatureSource(
        address operator,
        bytes32 _inputsHash,
        bytes memory _signature
    ) public pure returns (bool) {
        return operator == getSignerFromMessageHash(_inputsHash, _signature);
    }

    function getSignerFromMessageHash(
        bytes32 _inputsHash,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 _ethMessageHash = getEthMessageHash(_inputsHash);
        (bytes32 r, bytes32 s, uint8 v) = _split(_signature);
        return ecrecover(_ethMessageHash, v, r, s);
    }

    function getEthMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function _split(bytes memory _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
    }
}
