// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface IConfigurableReserve {
  
  ///@notice struct to store the reserve rate mantissa for an address and a flag to indicate to use the default reserve rate
  struct ReserveRate{
      uint224 rateMantissa;
      bool useCustom;
  }

  /// @notice Returns the reserve rate for a particular source
  /// @param source The source for which the reserve rate should be return.  These are normally prize pools.
  /// @return The reserve rate as a fixed point 18 number, like Ether.  A rate of 0.05 = 50000000000000000
  function reserveRateMantissa(address source) external view returns (uint256);

  /// @notice Allows the owner of the contract to set the reserve rates for a given set of sources.
  /// @dev Length must match sources param.
  /// @param sources The sources for which to set the reserve rates.
  /// @param _reserveRates The respective ReserveRates for the sources.  
  function setReserveRateMantissa(address[] calldata sources,  uint224[] calldata _reserveRates, bool[] calldata useCustom) external;

  /// @notice Allows the owner of the contract to set the withdrawal strategy address
  /// @param strategist The new withdrawal strategist address
  function setWithdrawStrategist(address strategist) external;

  /// @notice Calls withdrawReserve on the Prize Pool
  /// @param prizePool The Prize Pool to withdraw reserve
  /// @param to The reserve transfer destination address
  function withdrawReserve(address prizePool, address to) external returns (uint256);

  /// @notice Sets the default ReserveRate mantissa
  /// @param _reserveRateMantissa The new default reserve rate mantissa
  function setDefaultReserveRateMantissa(uint224 _reserveRateMantissa) external;
  
  /// @notice Emitted when the reserve rate mantissa was updated for a prize pool
  /// @param prizePool The prize pool address for which the rate was set
  /// @param reserveRateMantissa The respective reserve rate for the prizepool.
  /// @param useCustom Whether to use the custom reserve rate (true) or the default (false)
  event ReserveRateMantissaSet(address indexed prizePool, uint256 reserveRateMantissa, bool useCustom);

  /// @notice Emitted when the withdraw strategist is changed
  /// @param strategist The updated strategist address
  event ReserveWithdrawStrategistChanged(address indexed strategist);

  /// @notice Emitted when the default reserve rate mantissa was updated
  /// @param rate The new updated default mantissa rate
  event DefaultReserveRateMantissaSet(uint256 rate);

}