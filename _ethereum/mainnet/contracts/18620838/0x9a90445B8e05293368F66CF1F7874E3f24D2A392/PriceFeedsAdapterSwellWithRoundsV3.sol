// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./PriceFeedsAdapterSwellWithRoundsV2.sol";

contract PriceFeedsAdapterSwellWithRoundsV3 is PriceFeedsAdapterSwellWithRoundsV2 {

  bytes32 constant private SWETH_ID = bytes32("SWETH");
  bytes32 constant private SWETH_ETH_ID = bytes32("SWETH/ETH");

  function getDataFeedIds() public pure override returns (bytes32[] memory dataFeedIds) {
    dataFeedIds = new bytes32[](2);
    dataFeedIds[0] = SWETH_ID;
    dataFeedIds[1] = SWETH_ETH_ID;
  }

  function getDataFeedIndex(bytes32 dataFeedId) public view override virtual returns (uint256) {
    if (dataFeedId == SWETH_ID) { return 0; }
    if (dataFeedId == SWETH_ETH_ID) { return 1; }
    revert DataFeedIdNotFound(dataFeedId);
  }
}
