// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IPolicy.sol";
import "./FauxblocksLib.sol";

contract TestPolicy is IPolicy {
  function acceptTransaction(address /* sender */, FauxblocksLib.Transaction memory /* trx */) public view override returns (FauxblocksLib.TransactionType code, bytes memory context) {
    code = FauxblocksLib.TransactionType.CALL;
    context = abi.encode(uint256(1));
  }
}
