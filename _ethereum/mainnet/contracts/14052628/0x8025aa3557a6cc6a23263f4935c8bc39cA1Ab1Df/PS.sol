// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./PaymentSplitter.sol";

contract PS is PaymentSplitter {

  address[] private _distributions = [
    0x6f52aB9EFF44FBd2D99EC8d73dcb59DEfA049970,
    0x22E38368DDacc3C5D2cd11ecbbcf7E46E0F54715,
    0xA4D872934e813BD15b55C77BfD6da99Ff3e9C35e
  ];

  uint[] private _Shares = [
    94,
    3,
    3
  ];

  constructor() PaymentSplitter(_distributions, _Shares) {}    

  function distributeAll() external {
    for (uint256 i = 0; i < _distributions.length; i++) {
      release(payable(_distributions[i]));
    }
  }
}