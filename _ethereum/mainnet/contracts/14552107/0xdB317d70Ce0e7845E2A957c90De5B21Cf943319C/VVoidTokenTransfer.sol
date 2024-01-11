// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20Token.sol";
import "./console.sol";

error FeeError(uint256 realAmount, uint256 fee);
error EqualError(uint256 noEqual);
error SendError(address sender);

contract VVoidTokenTransfer is Ownable {

  uint256 public txFee = 0.005 ether;

  event SendNotification(address sender);
  event SendERC20Notification(address sender);

  constructor() {}

  modifier checkFee {
    if(msg.value != txFee) revert FeeError(msg.value, txFee);
    _;
  }

  /**
    发送 ETH
   */
  function send(address[] calldata receivers, uint256[] calldata amounts) public payable {
    if (receivers.length != amounts.length){
      revert EqualError(receivers.length);
    }

    uint256 realAmount = msg.value;
    uint256 sendAmount = 0;

    for (uint i = 0; i < amounts.length; i++) {
      sendAmount += amounts[i];
    }
    sendAmount += txFee;
    if ((realAmount - sendAmount) != 0){
      revert FeeError(realAmount, txFee);
    }

    for (uint i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      uint256 amount = amounts[i];
      (bool sendStatus, ) = receiver.call{value: amount}("");
      if (!sendStatus) {
        revert SendError(receiver);
      }
    }
    emit SendNotification(msg.sender);
  }

  /**
    发送 ERC20
   */
  function sendERC20(address tokenAddress, address[] calldata receivers, uint256[] calldata amounts) public payable checkFee{
    ERC20Token token = ERC20Token(tokenAddress);
    
    for (uint i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      uint256 amount = amounts[i];
      token.transferFrom(msg.sender, receiver, amount);
    }

    emit SendERC20Notification(msg.sender);
  }

  /**
    修改 owner 权限
   */
  function changedOwner(address newOwner) public onlyOwner{
    transferOwnership(newOwner);
  }

  /**
    修改手续费
   */
  function changedTxFee(uint256 newTxFee) public onlyOwner{
    txFee = newTxFee;
  }

  /**
    取款
   */
  function withdraw() public onlyOwner {
    address _owner = owner();
    uint256 amount = address(this).balance;
    (bool sendStatus, ) = _owner.call{value: amount}("");
    if (!sendStatus){
      revert SendError(_owner);
    }
  }

  receive() external payable {}
  fallback() external payable {}
}