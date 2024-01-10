// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "./IMultiex.sol";
import "./OndoRegistryClient.sol";

/*
 * @title Multiex call
 * @notice Send all fee directly to creator
 */
abstract contract Multiex is OndoRegistryClient, IMultiex {
  function multiexcall(Call[] calldata calls)
    external
    override
    isAuthorized(OLib.GUARDIAN_ROLE)
    returns (bytes[] memory returnData)
  {
    returnData = new bytes[](calls.length);
    for (uint256 i = 0; i < calls.length; i++) {
      (bool success, bytes memory ret) = calls[i].target.call(calls[i].data);
      require(success, "Multicall aggregate: call failed");
      returnData[i] = ret;
    }
  }
}
