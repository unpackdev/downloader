// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "./xCAVO.sol";

contract TestxCAVO is xCAVO {
    function testSetExpectedPrice(uint price) external {
        expectedPriceInUQ = price;
    }
}