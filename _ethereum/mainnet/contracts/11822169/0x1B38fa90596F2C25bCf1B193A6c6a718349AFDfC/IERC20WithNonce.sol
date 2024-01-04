// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./ERC20.sol";

interface IERC20WithNonce is IERC20 {
  function _nonces(address user) external view returns (uint256);
}
