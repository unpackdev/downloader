pragma solidity 0.7.3;

interface IStorage {
  function underlyings(uint256) external view returns (address);
  function routerAddress() external view returns (address);
  function mainUnderlying() external view returns (address);
  function underlyingEnabled(address) external view returns (bool);
  function mainUnderlyingRoutes(address) external view returns (address[] memory);
}
