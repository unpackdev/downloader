// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./TurfShopEligibilityChecker.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";


// A Merklee Tree based eligiblity checker for Turf Shop.
// Requires the address to check, the Merkle proof, and the expected number of items to mint.
// That count is encoded into the tree. If all's well it will return that count to TurfShop for minting.

// Requires TurfShop to call back to confirmMint to mark this address as having been attended to.

// Don't use this for live checks, only snapshots, since it won't track plots that have changed hands.

contract MerkChecker is TurfShopEligibilityChecker, Ownable {

  address turfShopAddress;
  mapping(address => uint256) private _mintedPerAddress;

  bytes32 private _merkleRoot;

  constructor(address turfShopAddress_) {
    require(turfShopAddress_ != address(0), "Set the Turf Shop address!");
    turfShopAddress = turfShopAddress_;
  }

  function check(address addr, bytes32[] memory merkleProof, bytes memory data) external view returns (bool, uint) {

    require(_mintedPerAddress[addr] == 0, "already minted");

    (uint expectedCount) = abi.decode(data, (uint));
    
    bytes32 leaf = keccak256(abi.encodePacked(addr, expectedCount));
    if(MerkleProof.verify(merkleProof, _merkleRoot, leaf)){
      return (true, expectedCount);
    } else {
      return (false, 0);
    }  
  }

  function confirmMint(address addr, uint256 count) external {
    require(msg.sender == turfShopAddress, "nope");
    _mintedPerAddress[addr] = count;
  }

  function setMerkleRoot(bytes32 merkRoot) external onlyOwner {
    _merkleRoot = merkRoot;
  }

}
