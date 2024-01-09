// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./MerkleProof.sol";

interface iAllowList {
    function isAllowed(
        address address_,
        bytes32[] memory proof_,
        address listOwner_
    ) external view returns (bool);
}

contract WhiteList is iAllowList {
    mapping(address => bytes32) public merkleRoots;

    function isAllowed(
        address addressToVerify,
        bytes32[] memory proof,
        address listOwner
    ) external view override returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addressToVerify));
        return MerkleProof.verify(proof, merkleRoots[listOwner], leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public {
        merkleRoots[msg.sender] = _merkleRoot;
    }
}
