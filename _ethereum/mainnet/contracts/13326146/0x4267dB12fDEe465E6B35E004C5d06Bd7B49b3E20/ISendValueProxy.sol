// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ISendValueProxy {
  function sendValue(address payable _to) external payable;
}
