// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


// solhint-disable-next-line max-line-length
// Refer to https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
interface IChainLinkAggregatorProxy {
  function decimals() external view returns (uint8);
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer, // rate in decimals of the token
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
