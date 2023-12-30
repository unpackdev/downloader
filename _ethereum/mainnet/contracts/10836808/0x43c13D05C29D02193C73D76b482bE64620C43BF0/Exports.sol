pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ShifterBorrowProxyLib.sol";

contract Exports {
  event InitializationActionsExport(ShifterBorrowProxyLib.InitializationAction[] actions);
  event ProxyRecordExport(ShifterBorrowProxyLib.ProxyRecord record);
  event TriggerParcelExport(ShifterBorrowProxyLib.TriggerParcel record);
}
