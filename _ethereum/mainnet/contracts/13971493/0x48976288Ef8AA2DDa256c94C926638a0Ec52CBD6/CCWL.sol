// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";

import "./MerkleProof.sol";

   interface iAllowList {
    function isAllowed(address address_, uint8 amount, bytes32[] memory proof_)
        external
        view
        returns (bool);
}
contract CCPS is Ownable, iAllowList {

bytes32 public merkleRoot = 0xe241e9c537356e29fd3030655e55d5902204b94d90931d9acbbde3a620532b09;
    
function isAllowed(address sender, uint8 amount, bytes32[] memory proof) external override view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender, amount));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

}