// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";

interface IDepositable {
  function depositAnchored(IERC20 token, address depositor, uint256 anchored_amount) external;
}