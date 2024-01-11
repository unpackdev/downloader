// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MerkleProof.sol";
import "./Context.sol";

contract MerkleAllowList is Context {

    bytes32 internal _merkleRoot;

    constructor(bytes32 merkleRoot) {
        _merkleRoot = merkleRoot;
    }

    function _setMerkleRoot(bytes32 newMerkleRoot) internal {
        _merkleRoot = newMerkleRoot;
    }

    bool public allowListEnabled = true;

    event EnabledAllowList();
    event DisableAllowList();

    modifier onlyPublicSale {
        require(!allowListEnabled, "Allow list is currently active");
        _;
    }

    function _enableAllowList() internal {
        allowListEnabled = true;
        emit EnabledAllowList();
    }

    function _disableAllowList() internal {
        allowListEnabled = false;
        emit DisableAllowList();
    }

    modifier canMint(bytes32[] calldata proof) {
        require(allowListEnabled, "Allow list is currently not active");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(proof, _merkleRoot, leaf), "User is not whitelisted");
        _;
    }

}