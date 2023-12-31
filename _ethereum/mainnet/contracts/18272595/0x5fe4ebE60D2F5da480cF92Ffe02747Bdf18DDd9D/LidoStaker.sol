// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LidoStakerBase.sol";
import "./IReward.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo. 
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/


contract LidoStaker is LidoStakerBase {
        
    address rewardsContract;

    function setRewardsContract(address _rewardsContract) public onlyOwner {
        rewardsContract = _rewardsContract;
    }   
    
    receive() external payable {
        require(msg.value > 0, "msg.value == 0");

        ILido(ST_ETH).submit{value: msg.value}(
            0x0000000000000000000000000000000000000000
        );

        uint256 stEthAmount = IERC20(ST_ETH).balanceOf(address(this));
        IERC20(ST_ETH).transfer(msg.sender, stEthAmount);
    
        uint256 remainingStEth = IERC20(ST_ETH).balanceOf(address(this));
        uint256 remainingEth = address(this).balance;

        require(remainingStEth <= 1, "!remainingStEth");
        require(remainingEth == 0, "!remainingEth");

        IReward(rewardsContract).applyBonus(msg.value);
    }
}
