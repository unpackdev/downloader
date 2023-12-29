// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20.sol";

interface ICLeverToken is IERC20 {
  function mint(address _recipient, uint256 _amount) external;

  function burn(uint256 _amount) external;

  function burnFrom(address _account, uint256 _amount) external;
}
