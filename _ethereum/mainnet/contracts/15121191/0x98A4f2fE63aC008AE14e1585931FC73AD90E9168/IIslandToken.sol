//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./IAccessControl.sol";

interface IIslandToken is IERC20 {
  function mint(address to, uint256 amount) external;
}
