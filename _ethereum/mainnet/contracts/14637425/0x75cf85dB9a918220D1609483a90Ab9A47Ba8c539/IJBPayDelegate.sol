// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC165.sol";
import "./JBDidPayData.sol";

interface IJBPayDelegate is IERC165 {
  function didPay(JBDidPayData calldata _data) external;
}
