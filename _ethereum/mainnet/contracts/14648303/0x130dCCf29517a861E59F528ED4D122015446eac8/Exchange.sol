//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./ExchangeCore.sol";
import "./TransferManager.sol";
import "./TransferExecutor.sol";

contract Exchange is ExchangeCore, TransferManager, TransferExecutor {
    constructor() EIP712("Exchange", "1.0.0") {}
}
