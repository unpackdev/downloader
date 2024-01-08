// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

import "./ERC20.sol";
import "./MerkleProof.sol";

contract OhGeez is ERC20, MerkleProof {
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    constructor(bytes32 _merkleRoot) ERC20("Oh..Geez", "OH-GEEZ") {
        _mint(address(this), 333e18);
        merkleRoot = _merkleRoot;
    }

    function claim(bytes32[] memory proof) external {
        require(!claimed[msg.sender], "FORBIDDEN");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(verify(merkleRoot, leaf, proof), "INVALID_PROOF");
        claimed[msg.sender] = true;
        _transfer(address(this), msg.sender, 1e18);
    }
}
