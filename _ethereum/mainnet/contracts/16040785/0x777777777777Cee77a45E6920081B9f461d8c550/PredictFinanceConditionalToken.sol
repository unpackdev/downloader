// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ConditionalTokens.sol";

contract PredictFinanceConditionalToken is ConditionalTokens {
    string public constant name = "Predict.finance Conditional Token";
    string public constant symbol = "PREDICT";

    constructor(address _weth) ConditionalTokens(_weth) {}
}
