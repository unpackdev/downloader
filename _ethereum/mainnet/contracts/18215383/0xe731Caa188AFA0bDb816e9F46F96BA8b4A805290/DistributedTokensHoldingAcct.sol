// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./HoldingAcct.sol";

contract DistributedTokensHoldingAcct is HoldingAcct {

    string constant description = "Cold storage account for EBET already distributed supply, all these tokens are either staked or held liquid by players on EarnBet Casino.";
    
    constructor(address _owner) HoldingAcct(_owner){ }
}