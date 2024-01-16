pragma solidity ^0.8.0;

contract SendEth {
  bool public allowed = false;

  function allowTransfer() external {
    allowed = true;
  }

  function disableTranfer() external {
    allowed = false;
  }

  function sendEth(address payable recipient) external payable {
    require(allowed, "Not allowed");
    recipient.transfer(msg.value);
  }
}