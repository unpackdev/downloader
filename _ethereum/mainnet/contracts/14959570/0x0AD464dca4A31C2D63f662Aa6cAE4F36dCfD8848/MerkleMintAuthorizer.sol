// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./MerkleProof.sol";

import "./BaseMinter.sol";

contract MerkleMintAuthorizer is BaseMinter {
  uint256 private immutable _userMintLimit;
  mapping(address => uint256) private _userMintCount;

  bytes32 private immutable _merkleRoot;
  uint256 private immutable _userMintPrice;

  constructor(
    address entryPoint,
    string memory mintName,
    uint256 totalMintLimit,
    uint256 userMintLimit,
    bytes32 merkleRoot,
    uint256 userMintPrice,
    uint256 startTime,
    uint256 endTime
  ) BaseMinter(entryPoint, mintName, totalMintLimit, startTime, endTime) {
    _userMintLimit = userMintLimit;
    _merkleRoot = merkleRoot;
    _userMintPrice = userMintPrice;
  }

  function getProofRequired() external view override returns (bool) {
    return _merkleRoot != bytes32(0);
  }

  function getUserMintPrice(address, bytes32[] memory) external view override returns (uint256) {
    return _userMintPrice;
  }

  function getUserMintLimit(address, bytes32[] memory) external view override returns (uint256) {
    return _userMintLimit;
  }

  function getUserMintCount(address user) external view override returns (uint256) {
    return _userMintCount[user];
  }

  function authorizeMint(
    address sender,
    uint256 value,
    uint256 number,
    bytes32[] memory proof
  ) external override {
    _authorizeMint(number);

    uint256 newMintCount = _userMintCount[sender] + number;
    require(newMintCount <= _userMintLimit, "Trying to mint more than allowed");
    _userMintCount[sender] = newMintCount;

    require(_merkleRoot == bytes32(0) || MerkleProof.verify(
              proof, _merkleRoot, keccak256(abi.encodePacked(sender))),
            "Merkle proof failed");

    // We can't use "Insufficient funds" because ethers-io makes
    // some assumptions about specific error strings and throws an error
    // when it sees one...
    //   see: https://github.com/NomicFoundation/hardhat/issues/2489
    require(value >= _userMintPrice * number, "Insufficient payment");
  }
}
