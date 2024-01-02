// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IERC20.sol";

contract ReimbursementProposal {
    address public constant developerAddress = 0x9Ff3C1Bea9ffB56a78824FE29f457F066257DD58;
    IERC20 public constant TORN = IERC20(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);
    uint256 public constant reimbursementAmount = 6467 ether; // check scripts/calculateReimbursement.ts

    function executeProposal() public {
        TORN.transfer(developerAddress, reimbursementAmount);
    }
}
