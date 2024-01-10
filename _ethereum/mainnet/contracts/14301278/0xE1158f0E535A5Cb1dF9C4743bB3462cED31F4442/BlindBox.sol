// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./GenerativeBB.sol";
import "./NonGenerativeBB.sol";

contract BlindBox is NonGenerativeBB {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
     constructor() payable  {

    }

    /** 
    @dev this function is to buy box of any type.
    @param seriesId id of the series of whom box to bought.
    @param isGenerative flag to show either blindbox to be bought is of Generative blindbox type or Non-Generative
    
    */
    function buyBox(uint256 seriesId, bool isGenerative, uint256 currencyType, address collection, string memory ownerId, bytes32 user) public {
        if(isGenerative){
            // buyGenerativeBox(seriesId, currencyType);
        } else {
            buyNonGenBox(seriesId, currencyType, collection, ownerId, user);
        }
    }
    function buyBoxPayable(uint256 seriesId, bool isGenerative, address collection, bytes32 user) payable public {
        if(isGenerative){
            // buyGenBoxPayable(seriesId);
        } else {
            buyNonGenBoxPayable(seriesId, collection, user);
        }
    }

   fallback() payable external {}
    receive() payable external {}
}