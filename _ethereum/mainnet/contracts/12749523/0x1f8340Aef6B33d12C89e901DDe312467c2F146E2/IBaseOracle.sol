// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBaseOracle {
  
  function getICHIPrice(address pair_, address chainlink_) external view returns (uint256);
  function getBaseToken() external view returns (address);
  function decimals() external view returns (uint256);
}
