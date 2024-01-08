// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenerativeBB.sol";

contract NonGenerativeBB is GenerativeBB {

   using Counters for Counters.Counter;
    using SafeMath for uint256;

    constructor() public {

    }

/** 
    @dev function to add URIs in given series
        @param seriesId - id of the series in whom URIs to be added
        @param name - array of URI names to be added/updated
        @param uri - array of URIs to be added/updated
        @param rarity - array of URI rarity to be added/updated
    @notice
        1. all arrays should be of same length & sequence
        2. only owner of the smartcontract can add/update URIs
        3. you can not update one URI, should provide all to ensure data integrity & rarities
    */
    function setURIs(uint256 seriesId, string[] memory name, string[] memory uri, uint256[] memory rarity, uint256 copies) onlyOwner public {
        // uint256 totalRarity = 0;
        require(abi.encode(nonGenSeries[seriesId].name).length != 0,"Non-GenerativeSeries doesn't exist");
        require(name.length == uri.length && name.length == rarity.length, "URIs length mismatched");
        Counters.Counter storage _attrId = nonGenSeries[seriesId].attrId;
        // _attrId.reset();
        
        uint256 from = _attrId.current() + 1;
        for (uint256 index = 0; index < name.length; index++) {
            // totalRarity = totalRarity + rarity[index];
            // require( totalRarity <= 100, "Rarity sum of URIs can't exceed 100");
            _attrId.increment();
            nonGenSeries[seriesId].uris[_attrId.current()] = URI(name[index], uri[index], rarity[index], copies);
            
        }
        _CopiesData[seriesId].total = _attrId.current();
        // require( totalRarity == 100, "Rarity sum of URIs should be equal to 100");
        emit URIsAdded(seriesId,from, _attrId.current(), uri, name, rarity);
    }
/** 
    @dev function to start new NonGenerative Series
        @param name - name of the series
        @param seriesURI - series metadata tracking URI
        @param boxName - name of the boxes to be created in this series
        @param boxURI - blindbox's URI tracking its metadata
        @param startTime - start time of the series, (from whom its boxes will be available to get bought)
        @param endTime - end time of the series, (after whom its boxes will not be available to get bought)
        
       @notice only owner of smartcontract can trigger this function
    */
    function nonGenerativeSeries(address bCollection,string memory name, string memory seriesURI, string memory boxName, string memory boxURI, uint256 startTime, uint256 endTime, uint256 royalty) onlyOwner internal {
        require(startTime < endTime, "invalid series endTime");
        nonGenSeries[nonGenerativeSeriesId.current()].collection = bCollection;
        seriesIdsByCollection[bCollection][false].push(nonGenerativeSeriesId.current());
        nonGenSeries[nonGenerativeSeriesId.current()].name = name;
        nonGenSeries[nonGenerativeSeriesId.current()].seriesURI = seriesURI;
        nonGenSeries[nonGenerativeSeriesId.current()].boxName = boxName;
        nonGenSeries[nonGenerativeSeriesId.current()].boxURI = boxURI;
        nonGenSeries[nonGenerativeSeriesId.current()].startTime = startTime;
        nonGenSeries[nonGenerativeSeriesId.current()].endTime = endTime;
        nonGenseriesRoyalty[nonGenerativeSeriesId.current()] = royalty;

        emit NewNonGenSeries( nonGenerativeSeriesId.current(), name, startTime, endTime);
    }
    function setExtraParams(uint256 _baseCurrency, uint256[] memory allowedCurrecny, address _bankAddress, uint256 boxPrice, uint256 maxBoxes, uint256 perBoxNftMint) internal {
        baseCurrency[nonGenerativeSeriesId.current()] = _baseCurrency;
        _allowedCurrencies[nonGenerativeSeriesId.current()] = allowedCurrecny;
        bankAddress[nonGenerativeSeriesId.current()] = _bankAddress;
        nonGenSeries[nonGenerativeSeriesId.current()].price = boxPrice;
        nonGenSeries[nonGenerativeSeriesId.current()].maxBoxes = maxBoxes;
        nonGenSeries[nonGenerativeSeriesId.current()].perBoxNftMint = perBoxNftMint;
    }
    function getAllowedCurrencies(uint256 seriesId) public view returns(uint256[] memory) {
        return _allowedCurrencies[seriesId];
    }
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
    function buyNonGenBox(uint256 seriesId, uint256 currencyType) validateCurrencyType(seriesId,currencyType, false) internal {
        require(abi.encodePacked(nonGenSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(nonGenSeries[seriesId].maxBoxes > nonGenSeries[seriesId].boxId.current(),"boxes sold out");
        mintNonGenBox(seriesId);
            token = USD;
        
        uint256 price = dex.calculatePrice(nonGenSeries[seriesId].price , baseCurrency[seriesId], currencyType, 0, address(this), address(this));
        // if(currencyType == 0){
            price = price / 1000000000000;
        // }
        // escrow alia
        token.transferFrom(msg.sender, bankAddress[seriesId], price);
        // transfer box to buyer
        nonGenBoxOwner[_boxId.current()] = msg.sender;
        emitBuyBoxNonGen(seriesId, currencyType, price);
       
    }
    function timeTester() internal {
    if(deployTime+ 7 days <= block.timestamp)
    {
      deployTime = block.timestamp;
      vrf.getRandomNumber();
    }
  }
    function buyNonGenBoxPayable(uint256 seriesId) validateCurrencyType(seriesId,1, true)  internal {
        require(abi.encodePacked(nonGenSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(nonGenSeries[seriesId].maxBoxes > nonGenSeries[seriesId].boxId.current(),"boxes sold out");
        uint256 before_bal = MATIC.balanceOf(address(this));
        MATIC.deposit{value : msg.value}();
        uint256 after_bal = MATIC.balanceOf(address(this));
        uint256 depositAmount = after_bal - before_bal;
        uint256 price = dex.calculatePrice(nonGenSeries[seriesId].price , baseCurrency[seriesId], 1, 0, address(this), address(this));
        require(price <= depositAmount, "NFT 108");
        chainTransfer(bankAddress[seriesId], 1000, price);
        if(depositAmount - price > 0) chainTransfer(msg.sender, 1000, (depositAmount - price));
        mintNonGenBox(seriesId);
        // transfer box to buyer
        nonGenBoxOwner[_boxId.current()] = msg.sender;
        emitBuyBoxNonGen(seriesId, 1, price);
      }
    function emitBuyBoxNonGen(uint256 seriesId, uint256 currencyType, uint256 price) private{
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
/** 
    @dev function to open NonGenerative BlindBox
        @param boxId - id of blind box to be opened
    @notice given box should not be already opened.
    */
    function openNonGenBox(uint256 boxId) public {
        require(nonGenBoxOwner[boxId] == msg.sender, "Box not owned");
        require(!boxesNonGen[boxId].isOpened, "Box already opened");
        _openNonGenBox(boxId);

        emit BoxOpenedNonGen(boxId);
    }
/** 
    @dev utility function to open NonGenerative BlindBox
        @param boxId - id of blind box to be opened
    @notice given box should not be already opened.
    */
    function _openNonGenBox(uint256 boxId) private {
        uint256 sId = boxesNonGen[boxId].series;
        address collection = nonGenSeries[sId].collection;
    timeTester();
        // uint256 attrType = nonGenSeries[sId].attrType.current();
        uint256 rand =  vrf.getRandomVal();
        uint256 rand1;
        // uint256[] memory uris = new uint256[](_CopiesData[sId].total);
        uint256 tokenId;
        // uris = getRandURIs(sId, _CopiesData[sId].total);
        for (uint256 j = 0; j < boxesNonGen[boxId].countNFTs; j++) {
          rand1 = uint256(keccak256(abi.encodePacked(block.coinbase, rand, msg.sender, j))).mod(_CopiesData[sId].total); // to keep each iteration further randomize and reducing fee of invoking VRF on each iteration.
          tokenId = dex.mintWithCollection(collection, msg.sender, nonGenSeries[sId].uris[rand1].uri, nonGenseriesRoyalty[sId] );
          _CopiesData[sId].nftCopies[rand1]++;
          if(_CopiesData[sId].nftCopies[rand1] >= nonGenSeries[sId].uris[rand1].copies){
              URI storage temp = nonGenSeries[sId].uris[rand1];
            nonGenSeries[sId].uris[rand1] = nonGenSeries[sId].uris[_CopiesData[sId].total];
            nonGenSeries[sId].uris[_CopiesData[sId].total] = temp;
            _CopiesData[sId].total--;
            
          }
          emit NonGenNFTMinted(boxId, tokenId, msg.sender, collection, rand1);
        }
        boxesNonGen[boxId].isOpened = true;
       
    }
/** 
    @dev utility function to get Random URIs of given series based on URI's rarities.
        @param seriesId - id of nongenerative series
        @param countNFTs - total NFTs to be randomly selected and minted.
    */
    function getRandURIs(uint256 seriesId, uint256 countNFTs) internal view returns(uint256[] memory) {
        uint256[] memory URIs = new uint256[](countNFTs);
        // uint256[] memory uris = new uint256[](100);
        URI memory uri;
        uint256 occurence;
        uint256 i = 0;
        // populate attributes in array as per their rarity
        for (uint256 uriId = 1; uriId <= nonGenSeries[seriesId].attrId.current(); uriId++) {
            uri = nonGenSeries[seriesId].uris[uriId];
            // occurence = getOccurency(attr, attrType);
            occurence = uri.rarity;
            for (uint256 index = 0; index < occurence; index++) {
                URIs[i] = uriId;
                i++;
            }
        }
        // generate rand num through VRF out of 100 (size of array) can increase size or decrase based on attributes quantity
        
        // pic thos uriIds and return
        return URIs;
    }
    
    // events
    event NewNonGenSeries(uint256 indexed seriesId, string name, uint256 startTime, uint256 endTime);
    event BoxMintNonGen(uint256 boxId, uint256 seriesId);
    // event AttributesAdded(uint256 indexed boxId, uint256 indexed attrType, uint256 fromm, uint256 to);
    event URIsAdded(uint256 indexed boxId, uint256 from, uint256 to, string[] uris, string[] name, uint256[] rarity);
    event BuyBoxNonGen(uint256 boxId, uint256 seriesId, uint256 orignalPrice, uint256 currencyType, address collection, address from,uint256 baseCurrency, uint256 calculated);
    event BoxOpenedNonGen(uint256 indexed boxId);
    event NonGenNFTMinted(uint256 indexed boxId, uint256 tokenId, address from, address collection, uint256 uriIndex );
    // event BlackList(uint256 indexed seriesId, bytes32 indexed combHash, bool flag);
    

}