// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Auth.sol";
import "./BitMaps.sol";
import "./MerkleProof.sol";

abstract contract WhitelistModule is Auth {
    using BitMaps for BitMaps.BitMap;

    struct Whitelist {
        uint192 price;
        uint64 start;
        bytes32 merkleRoot;
    }

    mapping (uint256 => Whitelist) public whitelists;
    mapping (uint256 => BitMaps.BitMap) private _claimedWL;

    function createWLClaim(uint256 dropId, uint192 price, uint64 start, bytes32 root) requiresAuth public {
        whitelists[dropId] = Whitelist(price, start, root);
    }

    function flipWLState(uint256 dropId) requiresAuth public {
        whitelists[dropId].start = whitelists[dropId].start > 0 ? 0 : type(uint64).max;
    }

    function _purchaseThroughWhitelist(uint256 dropId, uint256 amount, uint256 index, bytes32[] calldata merkleProof) internal{
        Whitelist memory whitelist = whitelists[dropId];
        require(block.timestamp >= whitelist.start, "WL:INACTIVE");
        require(msg.value == whitelist.price * amount, "WL: INVALID MSG.VALUE");
        require(!_claimedWL[dropId].get(index), "WL:ALREADY CLAIMED");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount, index));
        require(MerkleProof.verify(merkleProof, whitelist.merkleRoot, node),"WL:INVALID PROOF");
        _claimedWL[dropId].set(index);
    }

    function isWLClaimed(uint256 dropId, uint256 index) public view returns (bool) {
        return _claimedWL[dropId].get(index);
    }
}