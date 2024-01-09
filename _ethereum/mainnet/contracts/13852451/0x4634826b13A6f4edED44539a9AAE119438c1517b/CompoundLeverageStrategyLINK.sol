// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundLeverageStrategy.sol";
import "./IToken.sol";

// solhint-disable no-empty-blocks
/// @title Deposit LINK in Compound and also borrow LINK based on leverage condition
contract CompoundLeverageStrategyLINK is CompoundLeverageStrategy {
    string public constant NAME = "CompoundLeverageStrategyLINK";
    string public constant VERSION = "3.0.22";

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) CompoundLeverageStrategy(_pool, _swapManager, _receiptToken) {}
}
