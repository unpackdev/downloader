// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";

contract EtherDistributor {
  function distributeEther(address payable [] memory _to, uint256[] memory _value) public payable {
    require(_to.length == _value.length);
    require(_to.length <= 255);

    for (uint8 i = 0; i < _to.length; i++) {
      Address.sendValue(_to[i], _value[i]);
    }

    if (address(this).balance > 0) {
      Address.sendValue(payable(msg.sender), address(this).balance);
    }
  }
}
