//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import "./IConnext.sol";
import "./IBridgeSenderAdapter.sol";
import "./IDataFeed.sol";

interface IConnextSenderAdapter is IBridgeSenderAdapter {
  // STATE VARIABLES

  function connext() external view returns (IConnext _connext);

  function dataFeed() external view returns (IDataFeed _dataFeed);
}
