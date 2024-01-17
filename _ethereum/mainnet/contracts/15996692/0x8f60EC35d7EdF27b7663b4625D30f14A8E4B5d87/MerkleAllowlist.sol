// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract MerkleAllowlist {
    
    mapping(uint256 => bytes32) internal _indexToAllowlistRoot;
    
    function _setAllowlistRoot(uint256 index_, bytes32 allowlistRoot_) internal virtual {
        _indexToAllowlistRoot[index_] = allowlistRoot_;
    }

    function isAllowlisted(uint256 index_, address address_, uint256 amount_,
    bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_, amount_));
        uint256 l = proof_.length;
        uint256 i; unchecked { do {
            _leaf = _leaf < proof_[i] ?
            keccak256(abi.encodePacked(_leaf, proof_[i])) :
            keccak256(abi.encodePacked(proof_[i], _leaf));
        } while (++i < l); }
        return _leaf == _indexToAllowlistRoot[index_];
    }
}