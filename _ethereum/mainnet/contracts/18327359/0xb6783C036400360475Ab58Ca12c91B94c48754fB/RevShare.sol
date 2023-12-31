pragma solidity ^0.8.18;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}




contract RevShare {
    
    IERC20 token;
    
    mapping(address => uint)  balances;
    
    constructor(address _token)   {
        token = IERC20(_token);
    }
    
    function distribute(address payable[] memory recipients) public payable {
        uint len = recipients.length;
        uint totalReward = msg.value;
        uint total;
        
        for (uint256 i = 0; i < len; i++) {
            uint bal = token.balanceOf(recipients[i]);
            balances[recipients[i]] = bal;
            total += bal;
        }

        
        for (uint256 i = 0; i < len; i++) {
         recipients[i].transfer(balances[recipients[i]] *  totalReward /total );
        }
    }
}