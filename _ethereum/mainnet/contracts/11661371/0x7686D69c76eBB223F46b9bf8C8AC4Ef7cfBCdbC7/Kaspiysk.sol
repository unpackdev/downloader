// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract Kaspiysk {

  address payable [] public queue;
  uint64[] public values;
  address payable ownerAddress;
  mapping (address => uint64) private fallbacks;
  uint72 stock;
  uint64 cursor;

  constructor() {
    ownerAddress = msg.sender;
  }

  function cacheOut() public {
    uint64 amount = fallbacks[msg.sender];
    if(amount > 0) {
      fallbacks[msg.sender] = 0;
      msg.sender.transfer(amount);
    }
  }

  receive () external payable {
    require (msg.value < 2**63);

    uint64 fee = uint64(msg.value / 100);
    fallbacks[ownerAddress] += fee;
    stock += uint64(msg.value - fee);
    queue.push(msg.sender);
    values.push(uint64(msg.value + msg.value/10));
    address payable addr = queue[cursor];
    uint64 value = values[cursor];
    if( value <= stock){
      delete queue[cursor];
      delete values[cursor];
      stock -= value;
      cursor += 1;
      (bool success, ) = addr.call{value: value}("");
      if(!success){
        fallbacks[addr] += value;
      }
    }
  }
}