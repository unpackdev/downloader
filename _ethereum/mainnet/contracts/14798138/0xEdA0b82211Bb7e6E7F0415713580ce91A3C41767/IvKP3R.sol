// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IvKP3R {
  // solhint-disable-next-line func-name-mixedcase
  function get_adjusted_ve_balance(address, address) external view returns (uint256);
}
