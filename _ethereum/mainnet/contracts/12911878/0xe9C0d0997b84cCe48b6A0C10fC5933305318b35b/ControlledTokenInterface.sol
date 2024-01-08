// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./IERC20Upgradeable.sol";

import "./TokenControllerInterface.sol";

interface ControlledTokenInterface is IERC20Upgradeable {
  function controller() external view returns (TokenControllerInterface);
  function controllerMint(address _user, uint256 _amount) external;
  function controllerBurn(address _user, uint256 _amount) external;
  function controllerBurnFrom(address _operator, address _user, uint256 _amount) external;
}
