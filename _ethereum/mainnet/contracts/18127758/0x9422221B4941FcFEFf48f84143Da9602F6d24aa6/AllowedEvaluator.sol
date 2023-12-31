// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.19;

/// @author: jason@unrealaccelerator.io
/// @title: AllowedEvaluator
/// @notice Merkle Proof for allow list implementations with amount

import "./MerkleProof.sol";

contract AllowedEvaluator {
    bytes32 internal _allowedMerkleRoot;

    function _setAllowedMerkleRoot(bytes32 allowedMerkleRoot_) internal {
        _allowedMerkleRoot = allowedMerkleRoot_;
    }

    function _validateMerkleProof(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        return
            MerkleProof.verify(
                merkleProof,
                _allowedMerkleRoot,
                keccak256(abi.encodePacked(index, account, amount))
            );
    }
}
