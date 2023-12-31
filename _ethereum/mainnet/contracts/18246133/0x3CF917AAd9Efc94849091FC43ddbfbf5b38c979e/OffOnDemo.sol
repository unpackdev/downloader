// SPDX-License-Identifier: MIT

// contract by steviep.eth

pragma solidity ^0.8.17;


interface IOffOn {
  function turnOff() external;
  function turnOn() external;
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}


contract OffOnDemo {
  IOffOn public offOn;
  address public owner;
  mapping(address => bool) public demoers;

  constructor (IOffOn _offOn) {
    offOn = _offOn;
  }

  function withdraw() external {
    require(msg.sender == owner, 'Only owner can withdraw');
    offOn.safeTransferFrom(address(this), owner, 0);
  }

  function turnOff() external {
    offOn.turnOff();
    demoers[msg.sender] = true;
  }

  function turnOn() external {
    offOn.turnOn();
    demoers[msg.sender] = true;
  }

  function onERC721Received(
    address,
    address from,
    uint256,
    bytes calldata
  ) external returns(bytes4) {
    if (msg.sender == address(offOn)) {
      owner = from;
      return this.onERC721Received.selector;
    } else {
      return bytes4(0);
    }
  }
}