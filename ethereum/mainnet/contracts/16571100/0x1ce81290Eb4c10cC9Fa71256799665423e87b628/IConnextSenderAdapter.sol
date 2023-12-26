//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import "./IBaseErrors.sol";
import "./IConnext.sol";
import "./IBridgeSenderAdapter.sol";
import "./IDataFeed.sol";

interface IConnextSenderAdapter is IBaseErrors, IBridgeSenderAdapter {
  // STATE VARIABLES

  /// @notice Gets the address of the DataFeed contract
  /// @return _dataFeed Address of the DataFeed contract
  function dataFeed() external view returns (IDataFeed _dataFeed);

  /// @notice Gets the ConnextHandler contract on this domain
  /// @return _connext Address of the ConnextHandler contract
  function connext() external view returns (IConnext _connext);

  // ERRORS

  /// @notice Thrown if the DataFeed contract is not the one calling for bridging observations
  error OnlyDataFeed();
}
