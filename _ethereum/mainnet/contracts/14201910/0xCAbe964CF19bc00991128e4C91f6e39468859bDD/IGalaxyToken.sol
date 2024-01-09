// SPDX-License-Identifier: MIT
pragma solidity >=0.4 <0.9;

interface IGalaxyToken {
  function destroyAndSend(address payable _recipient) external;
}
