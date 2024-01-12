// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract DopDistribution is Ownable {
  IERC20 public token;
  uint256 public amount;
  address public executor;
  address public receiver;

  constructor(IERC20 _token, uint _amount, address _executor, address _receiver) {
    token = _token;
    amount = _amount * 10 ** 18;
    executor = _executor;
    receiver = _receiver;
  }

  modifier onlyCaller() {
    require(msg.sender == owner() || msg.sender == executor, "Caller doesn't have access to call this function!");
    _;
  }

  function updateExecutor(address executor_) public onlyOwner {
    executor = executor_;
  }

  function updateReceiver(address receiver_) public onlyOwner {
    receiver = receiver_;
  }

  function updateTokenAmount(uint256 amount_) public onlyOwner {
    amount = amount_;
  }

  function updateTokenAddr(IERC20 tokenAddr) public onlyOwner {
    token = tokenAddr;
  }

  function withdraw(uint _amount) public onlyOwner {
    require(token.balanceOf(address(this)) > 0, "No balance!");
    require(token.balanceOf(address(this)) > _amount, "Insufficient balance!");

    require(token.transfer(msg.sender, _amount), "Withdraw failed!");
  }

  function send() external onlyCaller {
    require(receiver != address(0), "Null Address!");
    require(token.balanceOf(address(this)) > amount, "Insufficient balance!");

    require(token.transfer(receiver, amount), "Transfer failed!");
  }
}