// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC
// (github.com/unrealaccelerator/unrealaccelerator-contracts)
pragma solidity ^0.8.9;

/**
 *
 * @title SignatureEvaluator
 * @author: unrealaccelerator.io
 * @dev ECDSA signature of a standardized message
 *
 */

import "./ECDSA.sol";
import "./EnumerableSet.sol";

contract SignatureEvaluator {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private signers;
    mapping(bytes32 => bool) private usedMessages;

    constructor(address signer_) {
        require(signer_ != address(0), "Invalid signer address");
        _addSigner(signer_);
    }

    function _addSigner(address signer) internal {
        signers.add(signer);
    }

    function _removeSigner(address signer) internal {
        signers.remove(signer);
    }

    function _validateSignature(bytes memory data, bytes memory signature)
        internal
        returns (bool)
    {
        bytes32 message = _generateMessage(data);
        require(!usedMessages[message], "Message used");
        usedMessages[message] = true;
        return signers.contains(ECDSA.recover(message, signature));
    }

    function _generateMessage(bytes memory data)
        internal
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(data));
    }
}
