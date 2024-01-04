// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface ISwaps {
  function exchange_with_best_rate(
    address from,
    address to,
    uint amount,
    uint expected,
    address recipient
  ) external payable returns (uint);
}
