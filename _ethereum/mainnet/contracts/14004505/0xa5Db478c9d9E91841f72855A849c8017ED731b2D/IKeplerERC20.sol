// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";

interface IKeplerERC20 is IERC20 {

  function decimals() external view returns (uint8);

  function mint(address account_, uint256 ammount_) external;

  function burn(uint256 amount_) external;

  function burnFrom(address account_, uint256 amount_) external;

  function vault() external returns (address);
}
