// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

interface IERC20Proxy is IERC20 {
  function burnFrom( address account, uint256 amount ) external;
  function mintTo( address account, uint256 amount ) external;
}