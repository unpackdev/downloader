// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

import "./IERC20.sol";

interface IJusDeFi is IERC20 {
  function consult (uint amount) external view returns (uint);
  function burn (uint amount) external;
  function burnAndTransfer (address account, uint amount) external;
  function _feePool () external view returns (address payable);
}
