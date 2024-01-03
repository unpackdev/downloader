pragma solidity 0.6.12;

interface IMedianOracleGetter {
  /**
    * @notice Gets the current value of the oracle.
    * @return Value: The current value.
    *         valid: Boolean whether the value is valid or not.
    */
  function getData() external returns (uint256, bool);
}