// stake: Lock tokens into our smart contract (Synthetix version?)
// withdraw: unlock tokens from our smart contract
// claimReward: users get their reward tokens
//      What's a good reward mechanism?
//      What's some good reward math?

// Added functionality ideas: Use users funds to fund liquidity pools to make income from that?

// SPDX-License-Identifier: MIT


pragma solidity 0.8.2;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";


import "./Owned.sol";
import "./TokensRecoverable.sol";


contract TokenSwap is ReentrancyGuard, TokensRecoverable {
 using SafeMath for uint256;

   IERC20 private  _tokenstaking;
   IERC20 private  _tokenreward;
   uint256 private _totalSupply;
   address admin;




  
 



 constructor(
        address _owner,
        IERC20 tokena_,
        IERC20 tokenb_,
        address safewallet
     ) Owned(_owner) {
     _tokenstaking = tokena_;
        _tokenreward = tokenb_; 
        admin=safewallet;

    }
    
function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
  


function tokena() public view virtual returns (IERC20) {
        return _tokenstaking;
    }

function tokenb() public view virtual returns (IERC20) {
        return _tokenreward;
    }




    




function Swapa(uint256 amount) external {
uint256 finalAmount = calculateCompound(amount);
uint256 tokenAmount =_tokenreward.balanceOf(address(this));  

require(amount >0, "amount cannot be 0");

require(tokenAmount > finalAmount, "amount cannot be 0");




_totalSupply = _totalSupply.add(finalAmount);

_tokenstaking.transferFrom(msg.sender,admin,amount);  
  emit Swap(msg.sender,amount,finalAmount,block.timestamp); 

_tokenreward.transfer(msg.sender,finalAmount);
     
}


   




    

  

 




 function calculateCompound(uint256 amount) public pure returns (uint256) {
      
 return  (amount * 660);

}








 
        
    
       
    



event Swap(address indexed user, uint256 amount, uint256 tokenamount ,uint256 timestamp);
event Withdrawn(address indexed user, uint256 amount);


}


