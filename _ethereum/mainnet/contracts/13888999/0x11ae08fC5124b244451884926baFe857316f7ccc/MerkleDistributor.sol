// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IERC20.sol";
import "./MerkleProof.sol";

contract MerkleDistributor {
  address public immutable token;
  bytes32 public immutable merkleRoot;
  mapping(address => bool) private claimed;
  uint256 private immutable airdropStart;

  event Claimed(address account, uint256 amount);

  constructor(address token_, bytes32 merkleRoot_) {
    token = token_;
    merkleRoot = merkleRoot_;
    airdropStart = block.timestamp;
  }

  function isClaimed(address user) public view returns (bool) {
    return claimed[user];
  }

  function claim(
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) public {
    require(!isClaimed(account), "MerkleDistributor: Drop already claimed.");
    bytes32 node = keccak256(abi.encodePacked(account, amount));

    require(
        MerkleProof.verify(merkleProof, merkleRoot, node),
        "MerkleDistributor: Invalid proof."
    );

    claimed[account] = true;
    require(IERC20(token).transfer(account, amount * 10**18), "MerkleDistributor: Transfer failed.");

    emit Claimed(account, amount);
  }

  function sweep() public {
    require(block.timestamp > airdropStart + 180 days, "MerkleDistributor: Airdrop period has not ended.");
    require(
      msg.sender == 0x1489A38EA1B5b1547301a480f19Fa17a0A3db223
      || msg.sender == 0x2F075618681D45458aE20E17ca3CCf1C797d6E1a,
      "MerkleDistributor: Only the owner can sweep."
    );
    require(
      IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this))),
      "MerkleDistributor: Transfer failed."
    );
  }
}