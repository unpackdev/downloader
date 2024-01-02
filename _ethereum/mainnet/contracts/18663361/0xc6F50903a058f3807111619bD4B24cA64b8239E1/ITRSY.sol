// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IERC20.sol";

interface ITRSY is IERC20 {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}
