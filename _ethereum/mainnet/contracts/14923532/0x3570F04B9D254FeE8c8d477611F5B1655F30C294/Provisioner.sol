// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC
// (https://github.com/unreal-accelerator/contracts)
pragma solidity ^0.8.9;

/**
 * @title Provisioner
 * @author unrealaccelerator.io
 * @dev This contract is an extension of the PaymentSplitter that provides a withdrawAll function
 *
 */

import "./PaymentSplitter.sol";

contract Provisioner is PaymentSplitter {
    event ProvisionsReleased();
    uint256 private _numberOfPayees;

    constructor(address[] memory _payees, uint256[] memory _shares)
        payable
        PaymentSplitter(_payees, _shares)
    {
        _numberOfPayees = _payees.length;
    }

    function withdrawAll() external {
        require(address(this).balance > 0, "No balance to withdraw");

        for (uint256 i = 0; i < _numberOfPayees; i++) {
            release(payable(payee(i)));
        }
        emit ProvisionsReleased();
    }
}
