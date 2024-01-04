// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./IERC20Upgradeable.sol";

interface ICompLike is IERC20Upgradeable {
  function getCurrentVotes(address account) external view returns (uint96);
  function delegate(address delegatee) external;
}
