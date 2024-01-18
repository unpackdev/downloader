//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import "./IDataReceiver.sol";
import "./IOracleSidechain.sol";

interface IBridgeReceiverAdapter {
  // FUNCTIONS

  function dataReceiver() external view returns (IDataReceiver _dataReceiver);

  /* NOTE: callback methods should be here declared */

  // ERRORS

  error UnauthorizedCaller();
}
