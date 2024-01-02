// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./ApeSwap_V2.sol";

contract ApeSwap is ApeSwap_V2 {
          

    constructor(
        address _factory,
        ITellerV2 _tellerV2,
        ILenderCommitmentForwarder _commitmentForwarder
    ) ApeSwap_V2(_factory,_tellerV2,_commitmentForwarder){
        
    }


}