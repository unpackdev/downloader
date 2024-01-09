// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MerkleProof.sol";

abstract contract Whitelisted {
    bytes32 private _whitelistRoot;

    modifier onlyWhitelisted(bytes32 leaf, bytes32[] memory proof) {
        require(_whitelistRoot == bytes32(0) || MerkleProof.verify(proof, _whitelistRoot, leaf), "proof is not valid");
        _;
    }

    function _setWhitelist(bytes32 root) internal {
        _whitelistRoot = root;
    }

    function getWhitelist() public view returns (bytes32) {
        return _whitelistRoot;
    }

    uint256[49] private __gap;
}