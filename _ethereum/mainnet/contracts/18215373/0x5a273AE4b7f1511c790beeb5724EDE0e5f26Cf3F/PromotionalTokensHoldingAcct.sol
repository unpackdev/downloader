// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./HoldingAcct.sol";

contract PromotionalTokensHoldingAcct is HoldingAcct {

    string constant description = "Holding account for EBET promotional tokens, initialized at 20% total supply.";
    
    constructor(address _owner) HoldingAcct(_owner){ }
}