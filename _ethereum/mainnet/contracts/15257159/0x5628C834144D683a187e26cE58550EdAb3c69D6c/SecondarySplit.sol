// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./PaymentSplitterStayCool.sol";
import "./Admin.sol";

contract StayCoolSplitter is PaymentSplitterStayCool, Admin {
    constructor(address[] memory payees, uint256[] memory shares_)
        PaymentSplitterStayCool(payees, shares_)
    {}

    function flush() public onlyAdmins {
        for (uint256 i = 0; i < _payees.length; i++) {
            address addr = _payees[i];
            release(payable(addr));
        }
    }

    function flushToken(IERC20 token) public onlyAdmins {
        for (uint256 i = 0; i < _payees.length; i++) {
            address addr = _payees[i];
            release(token, payable(addr));
        }
    }
}
