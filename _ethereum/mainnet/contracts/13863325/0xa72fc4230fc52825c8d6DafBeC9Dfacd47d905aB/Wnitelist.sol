// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./MerkleProof.sol";


import "./Accessable.sol";


contract Whitelist is Accessable {
    bytes32 _whitelistRoot = 0;

    constructor() {}

    function _setWhitelistRoot(bytes32 root) external onlyAdmin {
        _whitelistRoot = root;
    }

    function isWhitelistRootSeted() public view returns(bool){
        return (_whitelistRoot != bytes32(0));
    }

    function inWhitelist(address addr, bytes32[] memory proof) public view returns (bool) {
        require(isWhitelistRootSeted(), "Whitelist merkle proof root not setted");
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, _whitelistRoot, leaf);
    }
}