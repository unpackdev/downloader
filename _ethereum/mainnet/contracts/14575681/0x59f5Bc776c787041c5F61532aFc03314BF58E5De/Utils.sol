// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BlindboxStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract Utils is Ownable, BlindboxStorage{
     using Counters for Counters.Counter;
    using SafeMath for uint256;
   constructor() {

   }

  
   function calculatePrice(uint256 _price, uint256 base, uint256 currencyType) public view returns(uint256 price) {
    price = _price;
     (uint112 _reserve0, uint112 _reserve1,) =LPMATIC.getReserves();
    if(currencyType == 0 && base == 1){
      price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(_reserve1,1000000000000)),_reserve0);
    } else if(currencyType == 1 && base == 0){
      price = SafeMath.div(SafeMath.mul(price,_reserve0),SafeMath.mul(_reserve1,1000000000000));
    }
    
  }
  
  
    
}