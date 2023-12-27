// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ECDSA.sol";
import "./Ownable.sol";

contract BoxBetRewardsDistribution is Ownable {
  using ECDSA for bytes32;

  uint256 public nonce;
  mapping(address => mapping(uint256 => bool)) public redeemed;

  event RewardRedeemed(address indexed user, uint256 amount, uint256 nonce);

  receive() external payable {}

  function incrementNonce() external onlyOwner {
    nonce += 1;
  }

  function redeem(
    address bettorAddress,
    uint256 amount,
    bytes memory signature
  ) public {
    require(!redeemed[bettorAddress][nonce], "Already claimed");

    bytes32 hash = keccak256(abi.encodePacked(bettorAddress, amount, nonce));
    bytes32 messageHash = hash.toEthSignedMessageHash();

    require(messageHash.recover(signature) == owner(), "Invalid signature");

    redeemed[bettorAddress][nonce] = true;

    (bool success, ) = address(bettorAddress).call{value: amount}("");

    require(success, "Transfer failed");
    emit RewardRedeemed(bettorAddress, amount, nonce);
  }

  function withdraw() public onlyOwner {
    uint amount = address(this).balance;
    require(amount > 0, "Empty balance");

    (bool success, ) = owner().call{value: amount}("");
    require(success, "Transfer failed");
  }
}
