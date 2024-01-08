// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./IERC721.sol";

interface IERC721Minter is IERC721 {
  function mint(address to) external returns (bool success);
}

contract MerkleDistributor {

  address immutable public erc721address;
  bytes32 immutable public merkleRoot;

  mapping(address => bool) public isClaimed;

  constructor(bytes32 merkleRoot_, address erc721address_) {
    merkleRoot = merkleRoot_;
    erc721address = erc721address_;
  }

  function claim(
    address account,
    bytes32[] calldata proof
  ) external {
    require(!isClaimed[account], "Drop already claimed");
    require(_verify(_leaf(account), proof), "Invalid merkle proof");
    require(IERC721Minter(erc721address).mint(account), "MerkleDistributor: Mint failed.");
    _setClaimed(account);
  }

  function _setClaimed(address account) private {
    isClaimed[account] = true;
  }

  function _leaf(address account) internal pure returns (bytes32){
    return keccak256(abi.encodePacked(account));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool){
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }
}
