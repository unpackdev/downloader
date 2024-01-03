pragma solidity 0.6.12;

interface IMedianOracle {
  /**
   * @notice Pushes a report for the calling provider.
   * @param payload is expected to be 18 decimal fixed point number.
   */
  function pushReport(uint256 payload) external;
}