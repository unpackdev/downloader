// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IDistributor.sol";

/**
 * @title Cover Distributor
 * @author crypto-pumpkin
 */
contract CoverDistributor is IDistributor, Ownable {

  IERC20 public immutable safe2;
  address public immutable override token; // newly deployed Cover
  bytes32 public immutable override merkleRoot;
  uint256 public safe2Migrated;
  uint256 public override totalClaimed;

  mapping(uint256 => uint256) private claimedBitMap;

  constructor (address cover_, bytes32 merkleRoot_, address safe2_) {
    token = cover_;
    merkleRoot = merkleRoot_;
    safe2 = IERC20(safe2_);
  }

  function isClaimed(uint256 index) public view override returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override {
    require(!isClaimed(index), "CoverDistributor: Already claimed");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "CoverDistributor: Invalid proof");

    // Mark it claimed and send the token.
    totalClaimed = totalClaimed + amount;
    _setClaimed(index);
    ICOVER(token).mint(account, amount);

    emit Claimed(index, account, amount);
  }

  /// @notice only called by self
  function migrateSafe2() external {
    uint256 safe2Balance = safe2.balanceOf(msg.sender);

    require(safe2Balance > 0, "CoverDistributor: no safe2 balance");
    safe2.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, safe2Balance);
    ICOVER(token).mint(msg.sender, safe2Balance);
    safe2Migrated = safe2Migrated + safe2Balance;
  }

  // collect any token send by mistake
  function collectDust(address _token) external {
    if (_token == address(0)) { // token address(0) = ETH
      payable(owner()).transfer(address(this).balance);
    } else {
      uint256 balance = IERC20(_token).balanceOf(address(this));
      IERC20(_token).transfer(owner(), balance);
    }
  }

  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
  }
}

interface ICOVER {
  function mint(address _account, uint256 _amount) external;
}