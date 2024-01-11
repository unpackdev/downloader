// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.11;

import "./IERC20.sol";

interface IOxygen is IERC20 {
  function mint(address to, uint256 amount) external;

  function reward(address to, uint256 amount) external;

  function donate(address to, uint256 amount) external;

  function tax(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}
