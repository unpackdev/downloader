// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./IAddressProvider.sol";

interface ISTABLEX is IERC20 {
  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;

  function a() external view returns (IAddressProvider);
}
