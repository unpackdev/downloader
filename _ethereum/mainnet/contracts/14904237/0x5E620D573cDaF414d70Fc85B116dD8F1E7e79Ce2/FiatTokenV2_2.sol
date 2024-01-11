/*
 * Copyright (c) 2022, Circle Internet Financial Trading Company Limited.
 * All rights reserved.
 *
 * Circle Internet Financial Trading Company Limited CONFIDENTIAL
 *
 * This file includes unpublished proprietary source code of Circle Internet
 * Financial Trading Company Limited, Inc. The copyright notice above does not
 * evidence any actual or intended publication of such source code. Disclosure
 * of this source code or any related proprietary information is strictly
 * prohibited without the express written permission of Circle Internet Financial
 * Trading Company Limited.
 */

pragma solidity 0.6.12;

import "./FiatTokenV2_1.sol";

contract FiatTokenV2_2 is FiatTokenV2_1 {

    function updateNameSymbolCurrency(string memory _name, string memory _symbol, string memory _currency) external {
        name = _name;
        symbol = _symbol;
        currency = _currency;
    }
}
