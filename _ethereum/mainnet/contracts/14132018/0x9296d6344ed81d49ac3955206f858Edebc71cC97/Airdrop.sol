//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Airdrop is Ownable {
  IERC20 public token;
  bytes32 public root;
  uint256 public deadline;
  mapping(address => bool) public claimed;

  event Claimed(address indexed claimer, uint256 amount);

  constructor(
    IERC20 _token,
    bytes32 _root,
    uint256 _deadline
  ) {
    token = _token;
    root = _root;
    deadline = _deadline;
  }

  function setRoot(bytes32 _root) public onlyOwner {
    root = _root;
  }

  function setDeadline(uint256 _deadline) public onlyOwner {
    deadline = _deadline;
  }

  function withdraw(IERC20 _token) public onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
  }

  function claim(uint256 amount, bytes32[] memory proof) public {
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp < deadline, "claim ended");
    require(!claimed[msg.sender], "claimed");
    claimed[msg.sender] = true;
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
    require(MerkleProof.verify(proof, root, leaf), "invalid proof");
    require(token.transfer(msg.sender, amount), "token transfer failed");
    emit Claimed(msg.sender, amount);
  }
}
