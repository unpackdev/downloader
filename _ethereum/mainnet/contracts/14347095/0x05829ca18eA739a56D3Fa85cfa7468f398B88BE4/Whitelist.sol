// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./MerkleProof.sol";

/// @author tempest-sol
abstract contract Whitelist {

    bool public whitelistActive;

    bytes32 internal _merkleRoot;

    event WhitelistMerkleRootUpdated(bytes32 oldMerkleRoot, bytes32 newMerkleRoot);

    event WhitelistStatusFlipped(bool oldStatus, bool newStatus);

    function whitelistData(bytes32[] calldata _merkleProof) private view returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        valid = MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }

    modifier _canMintWhitelist(bytes32[] calldata merkleProof) {
        bool isValid = whitelistData(merkleProof);
        require(isValid, "not_whitelisted");
        _;
    }
}