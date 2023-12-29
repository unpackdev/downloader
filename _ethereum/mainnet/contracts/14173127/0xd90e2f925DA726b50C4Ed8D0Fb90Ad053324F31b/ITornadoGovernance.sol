// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./ITornadoVault.sol";

interface ITornadoGovernance {
  function lockedBalance(address account) external view returns (uint256);

  function userVault() external view returns (ITornadoVault);
}
