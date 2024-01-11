// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

/**
 * @dev SmoltingInu token interface
 */

interface ISmoltingInu is IERC20 {
  function decimals() external view returns (uint8);

  function gameMint(address _user, uint256 _amount) external;

  function gameBurn(address _user, uint256 _amount) external;
}
