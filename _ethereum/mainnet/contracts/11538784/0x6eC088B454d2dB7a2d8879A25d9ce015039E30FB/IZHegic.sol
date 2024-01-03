// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import "./IERC20.sol";

import "./IHegicPoolMetadata.sol";
import "./IGovernable.sol";

interface IZHegic is IERC20, IGovernable {
  function pool() external returns (IHegicPoolMetadata);
  
  function setPool(address _newPool) external;
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
}