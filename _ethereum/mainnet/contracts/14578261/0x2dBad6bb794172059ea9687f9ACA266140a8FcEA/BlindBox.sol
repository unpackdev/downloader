// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./GenerativeBB.sol";
import "./NonGenerativeBB.sol";

contract BlindBox is NonGenerativeBB {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    

     struct Series1 {
        string name;
        string seriesURI;
        string boxName;
        string boxURI;
        uint256 startTime;
        uint256 endTime;
        string collection; 
    }
    struct Series2 {
        uint256 maxBoxes;
        uint256 perBoxNftMint;
        uint256 perBoxPrice;
        address bankAddress;
        uint256 baseCurrency;
        uint256[] allowedCurrencies; 
        string name;
    }
    /** 
    @dev constructor initializing blindbox
    */
    constructor() payable  {

    }

    
    // add URIs/attributes in series [handled in respective BBs]
    function updateWhiteList(uint256 seriesId, bool isWhiteListed)onlyOwner public {
      _isWhiteListed[seriesId] = isWhiteListed;
    }
// add URIs/attributes in series [handled in respective BBs]
    function updateNonGenSupply(uint256 seriesId, uint256 maxSupply)onlyOwner public {
      nonGenSeries[seriesId].maxBoxes = maxSupply;
    }

    function reduceMintedBoxSupply(uint256 seriesId)onlyOwner public {
      nonGenSeries[seriesId].boxId.decrement();
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
     function getPerBoxLimit(uint256 seriesId) public view returns(uint256){
        return _perBoxUserLimit[seriesId];
    }
    
    fallback() payable external {}
    receive() payable external {}
  event SeriesInputValue(Series1 _series, uint256 seriesId, bool isGenerative, uint256 royalty, bool whiteListOnly);
    event Series1InputValue(Series2 _series, uint256 seriesId, bool isGenerative);
}