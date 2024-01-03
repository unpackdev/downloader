// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.12;

contract HolderSystem {
  address internal owner;

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;

  uint internal reentry_status;

  modifier isOwner(address _account) {
    require(owner == _account, "Restricted Access!");
    _;
  }

  modifier blockReEntry() {
    require(reentry_status != ENTRY_DISABLED, "Security Block");
    reentry_status = ENTRY_DISABLED;

    _;

    reentry_status = ENTRY_ENABLED;
  }

  constructor() public {
    reentry_status = ENTRY_ENABLED;

    owner = msg.sender;
  }

  function() external payable blockReEntry() {
  }

  function getSystemBalance() external view isOwner(msg.sender) returns (uint) {
    return address(this).balance;
  }
  
  function withdraw(uint _amount) external payable isOwner(msg.sender) blockReEntry() {
    require(address(this).balance >= _amount && _amount > 0, "Not enough funds");

    (bool success, ) = msg.sender.call.value(_amount)("");
    
    require(success, "Transfer failed");
  }

  function withdrawTo(address payable _to, uint _amount) external isOwner(msg.sender) blockReEntry() {
    require(address(this).balance >= _amount && _amount > 0, "Not enough funds");

    (bool success, ) = _to.call.value(_amount)("");
    
    require(success, "Transfer failed");
  }

  function changeOwner(address _addr) external isOwner(msg.sender) {
    owner = _addr;
  }
}