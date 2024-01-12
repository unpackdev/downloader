// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract SuperBockRoyalties is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  struct Balance {
    uint earned;
    uint withdrawn;
  }

  // token id => balance
  mapping(uint => Balance) public balances;

  // token id => creator address
  mapping(uint => address payable) public creators;

  // global balance
  Balance public contractBalance;

  event Earned(uint indexed token, uint indexed amount);
  event Withdrawn(uint indexed token, uint indexed amount, address indexed creator);
  event CreatorChanged(uint indexed token, address indexed creator);

  constructor () {
    _transferOwnership(msg.sender);
  }

  receive() external payable {}

  fallback() external payable {}

  function changeCreator(uint tokenId, address payable newCreator) external {
    require(creators[tokenId] == msg.sender, "Only creator can change his address");
    creators[tokenId] = newCreator;
  }

  function setCreators(uint[] memory tokenId, address[] memory creator) external onlyOwner {
    for (uint i = 0; i < tokenId.length; i++) {
      creators[tokenId[i]] = payable(creator[i]);
      emit CreatorChanged(tokenId[i], creator[i]);
    }
  }

  function addEarnings(uint[] calldata tokenIds, uint[] calldata amounts) external onlyOwner {

    require(
      amounts.length == tokenIds.length,
      "Revenues and tokenIds must have the same length"
    );

    Balance memory balance = contractBalance;

    uint bookBalance = balance.earned - balance.withdrawn;
    uint actualBalance = address(this).balance;
    uint unaccounted = actualBalance - bookBalance;
    uint newEarnings;

    for (uint i = 0; i < amounts.length; i++) {
      uint tokenId = tokenIds[i];
      balances[tokenId].earned += amounts[i];
      newEarnings += amounts[i];
      emit Earned(tokenId, amounts[i]);
    }

    require(
      newEarnings == unaccounted,
      "Reported earnings don't match the contract balance"
    );

    contractBalance.earned = balance.earned + uint(newEarnings);
  }

  function withdraw(uint[] calldata tokenIds) external nonReentrant {

    uint withdrawnAmount = 0;

    for (uint i = 0; i < tokenIds.length; i++) {

      uint tokenId = tokenIds[i];

      // check balance
      Balance memory balance = balances[tokenId];
      uint withdrawable = balance.earned - balance.withdrawn;
      withdrawnAmount += withdrawable;
      balance.withdrawn += withdrawable;

      // update balance
      balances[tokenId] = balance;

      // send eth
      address payable creator = creators[tokenId];
      (bool success, ) = creator.call{value : withdrawable}("");
      require(success, "Withdrawal failed");

      emit Withdrawn(tokenId, withdrawable, creator);
    }

    // sanity check
    Balance memory trackedBalance = contractBalance;
    trackedBalance.withdrawn += withdrawnAmount;
    require(trackedBalance.withdrawn <= trackedBalance.earned, "Withdrawals exceed earnings");

    // update global balance
    contractBalance = trackedBalance;
  }

}
