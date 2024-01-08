// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./MerkleProof.sol";

import "./IAlEthNFT.sol";

contract MerkleNFTDrop {

    IAlEthNFT public alEthNFT;
    bytes32 public merkleRoot;

    constructor(address _alEthNFT, bytes32 _merkleRoot) {
        alEthNFT = IAlEthNFT(_alEthNFT);
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 _tokenId, uint256 _tokenData, address _receiver, bytes32[] calldata _proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(_tokenId, _tokenData, _receiver));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "MerkleNFTDrop.claim: Proof invalid");
        // Mint NFT
        alEthNFT.mint(_tokenId, _tokenData, _receiver);
    }

}