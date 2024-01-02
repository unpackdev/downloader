// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

import "./SafeERC20.sol";
import "./MerkleProof.sol";

error AlreadyClaimed();
error InvalidProof();

contract MerkleDistributor {
  using SafeERC20 for IERC20;

  address public immutable token;
  bytes32 public immutable merkleRoot;

  // This is a packed array of booleans.
  mapping(address => bool) public hasClaimed;

  event Claimed(address indexed to, uint256 amount);


  constructor(address token_, bytes32 merkleRoot_) {
    token = token_;
    merkleRoot = merkleRoot_;
  }

  function claim(address account, uint256 amount, bytes32[] calldata merkleProof)
  public
  virtual
  {
    if (hasClaimed[account]) revert AlreadyClaimed();

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(account, amount));
    if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

    // Mark it claimed and send the token.
    hasClaimed[account] = true;
    IERC20(token).safeTransfer(account, amount);

    emit Claimed(account, amount);
  }
}
