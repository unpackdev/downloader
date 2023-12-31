// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract StakingContract {
    uint rewardPercent = 100000;

    event tokensStaked(address from, uint256 amount);
    event TokensUnstaked(address to, uint256 amount);
    struct stake{
       uint amount;
       uint time;

    }
    mapping (address => stake) public stakes;
    function _deposit(address from , uint _amount) internal{
        require(stakes[from].amount == 0 , "Unstake first");
        stakes[from] = stake({
            amount: _amount ,
            time:block.timestamp
        });
        emit tokensStaked(from, _amount);
    }
    function _withdraw(address to) internal{
         require(stakes[to].amount > 0 , "zero staked");
         stakes[to].amount = 0;
         stakes[to].time = 0;
         //emit TokensUnstaked(to, rewardCalculation(to));
     }
   
     function rewardCalculation(address to) public view returns(uint){
         uint timeDifferent = block.timestamp - stakes[to].time;
         uint reward =stakes[to].amount + (stakes[to].amount  * timeDifferent / rewardPercent);
         return reward;
     }
}