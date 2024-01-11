// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenerativeBB.sol";

contract NonGenerativeBB is GenerativeBB {
 using Counters for Counters.Counter;
    using SafeMath for uint256;
    /** 
    @dev utility function to mint NonGenerative BlindBox
        @param seriesId - id of NonGenerative Series whose box to be opened
    @notice given series should not be ended or its max boxes already minted.
    */
    function mintNonGenBox(uint256 seriesId) private {
        require(nonGenSeries[seriesId].startTime <= block.timestamp, "series not started");
        require(nonGenSeries[seriesId].endTime >= block.timestamp, "series ended");
        require(nonGenSeries[seriesId].maxBoxes > nonGenSeries[seriesId].boxId.current(),"max boxes minted of this series");
        nonGenSeries[seriesId].boxId.increment(); // incrementing boxCount minted
        _boxId.increment(); // incrementing to get boxId

        boxesNonGen[_boxId.current()].name = nonGenSeries[seriesId].boxName;
        boxesNonGen[_boxId.current()].boxURI = nonGenSeries[seriesId].boxURI;
        boxesNonGen[_boxId.current()].series = seriesId;
        boxesNonGen[_boxId.current()].countNFTs = nonGenSeries[seriesId].perBoxNftMint;
       
        // uint256[] attributes;    // attributes setting in another mapping per boxId. note: series should've all attributes [Done]
        // uint256 attributesRarity; // rarity should be 100, how to ensure ? 
                                    //from available attrubets fill them in 100 index of array as per their rarity. divide all available rarites into 100
        emit BoxMintNonGen(_boxId.current(), seriesId);

    }
    modifier validateCurrencyType(uint256 seriesId, uint256 currencyType, bool isPayable) {
        bool isValid = false;
        uint256[] storage allowedCurrencies = _allowedCurrencies[seriesId];
        for (uint256 index = 0; index < allowedCurrencies.length; index++) {
            if(allowedCurrencies[index] == currencyType){
                isValid = true;
            }
        }
        require(isValid, "123");
        require((isPayable && currencyType == 1) || currencyType < 1, "126");
        _;
    }
    
/** 
    @dev function to buy NonGenerative BlindBox
        @param seriesId - id of NonGenerative Series whose box to be bought
    @notice given series should not be ended or its max boxes already minted.
    */
    function buyNonGenBox(uint256 seriesId, uint256 currencyType, address collection, string memory ownerId, bytes32 user) validateCurrencyType(seriesId,currencyType, false) internal {
        require(!_isWhiteListed[seriesId] || crypoWhiteList[msg.sender][seriesId], "not authorize");
        require(abi.encodePacked(nonGenSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(nonGenSeries[seriesId].maxBoxes > nonGenSeries[seriesId].boxId.current(),"boxes sold out");
        mintNonGenBox(seriesId);
        token = USD;
        
        uint256 price = calculatePrice(nonGenSeries[seriesId].price, baseCurrency[seriesId], currencyType);
        // if(currencyType == 0){
            // price = price / 1000000000000;
            price = SafeMath.div(price, 1000000000000);
        // }
        // escrow alia
        token.transferFrom(msg.sender, bankAddress[seriesId], price);
        // transfer box to buyer
        nonGenBoxOwner[_boxId.current()] = msg.sender;
        emitBuyBoxNonGen(seriesId, currencyType, price, collection, ownerId);
       
    }

   
    
    function emitBuyBoxNonGen(uint256 seriesId, uint256 currencyType, uint256 price, address collection, string memory ownerId) private{
            require(_boxesCrytpoUser[msg.sender][seriesId] < _perBoxUserLimit[seriesId], "Limit reach" );
     
        _openNonGenBoxOffchain(_boxId.current(), collection);
        _boxesCrytpoUser[msg.sender][seriesId]++;
        _boxesNoncryptoUser[ownerId][seriesId]++;

    emit BuyBoxNonGen(_boxId.current(), seriesId, nonGenSeries[seriesId].price, currencyType, nonGenSeries[seriesId].collection, msg.sender, baseCurrency[seriesId], price);
    }
//     function chainTransfer(address _address, uint256 percentage, uint256 price) private {
//       address payable newAddress = payable(_address);
//       uint256 initialBalance;
//       uint256 newBalance;
//       initialBalance = address(this).balance;
//       MATIC.withdraw(SafeMath.div(SafeMath.mul(price,percentage), 1000));
//       newBalance = address(this).balance.sub(initialBalance);
//     //   newAddress.transfer(newBalance);
//     (bool success, ) = newAddress.call{value: newBalance}("");
//     require(success, "Failed to send Ether");
//   }

    function _openNonGenBoxOffchain(uint256 boxId, address collection) private {
        uint256 sId = boxesGen[boxId].series;
        // uint256 rand = getRand();
        uint256 from;
        uint256 to;
        (from, to) =dex.mintBlindbox(collection, msg.sender, boxesNonGen[boxId].countNFTs, bankAddress[sId], nonGenseriesRoyalty[sId], sId);   // this function should be implemented in DEX contract to return (uint256, uint256) tokenIds, for reference look into Collection.sol mint func. (can be found at Collection/Collection.sol of same repo)
        boxesNonGen[boxId].isOpened = true;
        emit NonGenNFTsMinted(sId, boxId, from, to, 0, boxesNonGen[boxId].countNFTs);
    }

    
    
    // events
    event BoxMintNonGen(uint256 boxId, uint256 seriesId);
    // event AttributesAdded(uint256 indexed boxId, uint256 indexed attrType, uint256 fromm, uint256 to);
    event BuyBoxNonGen(uint256 boxId, uint256 seriesId, uint256 orignalPrice, uint256 currencyType, string collection, address from,uint256 baseCurrency, uint256 calculated);
    event BoxOpenedNonGen(uint256 indexed boxId);
   // event BlackList(uint256 indexed seriesId, bytes32 indexed combHash, bool flag);
    event NonGenNFTsMinted(uint256 seriesId, uint256 indexed boxId, uint256 from, uint256 to, uint256 rand, uint256 countNFTs);
    
}