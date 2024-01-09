// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
import "./IERC20.sol";

interface IVufi is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}
