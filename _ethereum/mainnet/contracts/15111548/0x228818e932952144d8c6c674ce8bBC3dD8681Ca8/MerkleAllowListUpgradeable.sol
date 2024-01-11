// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

contract MerkleAllowListUpgradeable is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    bool public isAllowlistEnabled;
    bytes32 private _whitelistMerkleRoot;

    mapping(address => uint256) public _minted;

    function setAllowlist(bool _enable) public onlyOwner {
        isAllowlistEnabled = _enable;
    }

    function isWhitelisted(bytes32[] memory proof, uint256 max) public view {
        require(_whitelistMerkleRoot != "", "merkle tree not set");
        require(
            MerkleProofUpgradeable.verify(
                proof,
                _whitelistMerkleRoot,
                keccak256(abi.encode(_msgSender(), max))
            ),
            "validation failed"
        );
    }

    function setWhitelistMerkleRoot(bytes32 newMerkleRoot_) external onlyOwner {
        _whitelistMerkleRoot = newMerkleRoot_;
    }
}
