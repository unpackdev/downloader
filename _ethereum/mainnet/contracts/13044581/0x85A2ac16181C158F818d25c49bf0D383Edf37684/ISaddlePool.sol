pragma solidity ^0.8.5;

interface ISaddlePool {
  /// @notice Computes current virtual price
  function getVirtualPrice() external view returns (uint256);

  /// @notice Returns balance for the token defined by the provided index
  function getTokenBalance(uint8 index) external view returns (uint256);

  /// @notice Returns the address of the token for the provided index
  function getToken(uint8 index) external view returns (address);
}
