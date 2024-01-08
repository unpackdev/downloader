// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./IERC721.sol";
import "./Ownable.sol";

interface IERC721Minter is IERC721 {
  function mint(address to) external returns (bool success);
}

contract MerkleDistributor is Ownable {

  address immutable public erc721address;

  // edition => merkleRoot
  mapping(uint256 => bytes32) public merkleRoots;

  mapping(address => bool) public isClaimed;

  constructor(bytes32 merkleRoot_, address erc721address_) {
    merkleRoots[1] = merkleRoot_;
    erc721address = erc721address_;
  }

  function claim(
    address account,
    bytes32[] calldata proof,
    uint256 edition
  ) external {
    require(!isClaimed[account], "Drop already claimed");
    require(_verify(_leaf(account), proof, edition), "Invalid merkle proof");
    require(IERC721Minter(erc721address).mint(account), "MerkleDistributor: Mint failed.");
    _setClaimed(account);
  }

  function _setClaimed(address account) private {
    isClaimed[account] = true;
  }

  function _leaf(address account) internal pure returns (bytes32){
    return keccak256(abi.encodePacked(account));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof, uint256 edition) internal view returns (bool){
    return MerkleProof.verify(proof, merkleRoots[edition], leaf);
  }

  function addMerkleRoot(uint256 edition, bytes32 merkleroot) public onlyOwner() {
    require(merkleRoots[edition] == 0, "Edition already Exists!, cannot modify.");
    merkleRoots[edition] = merkleroot;
  }

}
