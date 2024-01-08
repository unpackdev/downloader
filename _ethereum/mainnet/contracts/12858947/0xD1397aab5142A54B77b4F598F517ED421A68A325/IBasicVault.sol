// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

interface IBasicVault {
  function isPaused() external view returns (bool);

  function getRegistry() external view returns (address);
}
