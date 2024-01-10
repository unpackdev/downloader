// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity 0.8.7;

import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract Vault is PaymentSplitter, ReentrancyGuard {
    address[] private payees;

    constructor(address[] memory _payees, uint[] memory _shares)
    PaymentSplitter(_payees, _shares)
    {
        payees = _payees;
    }

    function releaseTotal() external nonReentrant {
        for(uint256 i; i < payees.length; i++){
            release(payable(payees[i]));
        }
    }

    function releaseTotal(IERC20 token) external nonReentrant {
        for(uint256 i; i < payees.length; i++){
            release(token, payable(payees[i]));
        }
    }
}
