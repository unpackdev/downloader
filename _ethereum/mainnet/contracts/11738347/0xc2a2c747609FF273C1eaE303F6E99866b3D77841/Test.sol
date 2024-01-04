// SPDX-License-Identifier: No License (None)
pragma solidity ^0.6.9;


contract Test {

    function address_belongs(address adr) external pure returns(address) {
        return address(0);
    }

    function balanceOf(address adr) external pure returns(uint256 bal){
        if (adr == address(0x94BAc24A28671Dfd7dC4E69D1010426aa5DFc7a0)) 
            bal = 1000000;
    }
    
    function totalSupply() external pure returns(uint256){
        return 1000000;
    }
    
}