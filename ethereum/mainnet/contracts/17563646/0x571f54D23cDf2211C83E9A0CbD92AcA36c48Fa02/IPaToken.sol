// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IAccessControl.sol";
import "./draft-IERC2612.sol";

interface IPaToken is IERC2612 {
  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;

  function accessController() external view returns (IAccessControl);
}
