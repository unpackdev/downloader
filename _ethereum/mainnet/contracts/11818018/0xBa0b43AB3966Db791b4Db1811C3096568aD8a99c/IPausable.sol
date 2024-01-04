// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IPausable {
  event Paused(bool _paused);

  function pause(bool _paused) external;
}
