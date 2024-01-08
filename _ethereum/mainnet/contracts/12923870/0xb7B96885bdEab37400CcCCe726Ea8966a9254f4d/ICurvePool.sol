pragma solidity ^0.8.5;

interface ICurvePool {
  /// @notice Computes current virtual price
  function get_virtual_price() external view returns (uint256);

  /// @notice Cached virtual price, used internally
  function virtual_price() external view returns (uint256);

  /// @notice Current full profit
  function xcp_profit() external view returns (uint256);

  /// @notice Full profit at last claim of admin fees
  function xcp_profit_a() external view returns (uint256);

  /// @notice Pool admin fee
  function admin_fee() external view returns (uint256);

  /// @notice Pool admin fee
  function balances(uint256 index) external view returns (uint256);

  /// @notice Returns the address of the token for the provided index
  function coins(uint256 index) external view returns (address);
}
