pragma solidity ^0.6.0;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IShifterERC20 {
  function fromUnderlying(uint256 amount) external returns (uint256);
}
  
