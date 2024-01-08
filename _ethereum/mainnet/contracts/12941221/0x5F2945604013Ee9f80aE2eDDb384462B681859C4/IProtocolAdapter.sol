// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10;
import "./IAdapterRegistry.sol";


interface IProtocolAdapter {
  event MarketFrozen(address token);

  event MarketUnfrozen(address token);

  event AdapterFrozen(address adapter);

  event AdapterUnfrozen(address adapter);

  function registry() external view returns (IAdapterRegistry);

  function frozenAdapters(uint256 index) external view returns (address);

  function frozenTokens(uint256 index) external view returns (address);

  function totalMapped() external view returns (uint256);

  function protocol() external view returns (string memory);

  function getUnmapped() external view returns (address[] memory tokens);

  function getUnmappedUpTo(uint256 max) external view returns (address[] memory tokens);

  function map(uint256 max) external;

  function unfreezeAdapter(uint256 index) external;

  function unfreezeToken(uint256 index) external;

  function freezeAdapter(address adapter) external;
}