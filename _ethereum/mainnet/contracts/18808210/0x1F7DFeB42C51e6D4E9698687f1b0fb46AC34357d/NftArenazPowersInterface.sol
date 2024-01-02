// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface NftArenazPowersInterface {

    function nftPowerMerkleRoots(address _address) external view returns (bytes32);

    function verifyNftPower(bytes32[] calldata merkleProof, uint256 nftId, uint256 nftPower, address nftContractAddress) external view returns (bool);

    function setNftPowerMerkleRoot(address nftContractAddress, bytes32 merkleRoot) external;
}
