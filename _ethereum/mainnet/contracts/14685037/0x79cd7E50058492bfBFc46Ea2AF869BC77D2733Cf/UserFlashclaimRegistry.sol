// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./AirdropFlashLoanReceiver.sol";

contract UserFlashclaimRegistry {
  address public bnftRegistry;
  mapping(address => address) public userReceivers;

  constructor(address bnftRegistry_) {
    bnftRegistry = bnftRegistry_;
  }

  function createReceiver() public {
    AirdropFlashLoanReceiver receiver = new AirdropFlashLoanReceiver(msg.sender, bnftRegistry, 1);
    userReceivers[msg.sender] = address(receiver);
  }
}
