// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./NftArenazPowersInterface.sol";

contract NftArenazPowers is Ownable, NftArenazPowersInterface {
    mapping(address => bytes32) public nftPowerMerkleRoots;

    function verifyNftPower(bytes32[] calldata merkleProof, uint256 nftId, uint256 nftPower, address nftContractAddress) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encode(nftId, nftPower));
        return MerkleProof.verify(merkleProof, nftPowerMerkleRoots[nftContractAddress], leaf);
    }

    function setNftPowerMerkleRoot(address nftContractAddress, bytes32 merkleRoot) external onlyOwner
    {
        nftPowerMerkleRoots[nftContractAddress] = merkleRoot;
    }
}
