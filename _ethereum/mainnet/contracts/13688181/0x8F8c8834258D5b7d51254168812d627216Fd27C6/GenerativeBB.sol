// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Utils.sol";
/**
@title GenerativeBB 
- this contract of blindbox's type Generative. which deals with all the operations of Generative blinboxes & series
 */
contract GenerativeBB is Utils {
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    constructor()  {

    }


    /** 
    @dev function to add attributes/traits in given series
        @param seriesId - id of the series in whom attributes to be added
        @param attrType - attribute Type id whose variants(attributes) to be updated, pass attrType=0 is want to add new attributeType.
        @param name - array of attributes names to be added/updated
        @param uri - array of attributes URIs to be added/updated
        @param rarity - array of attributes rarity to be added/updated
    @notice
        1. all arrays should be of same length & sequence
        2. only owner of the smartcontract can add/update attributes
        3. you can not update one attribute, should provide all to attributes of given attrType# ensure data integrity & rarities
    */
    function setAttributes(uint256 seriesId, uint256 attrType, string[] memory name, string[] memory uri, uint256[] memory rarity) onlyOwner public {
        uint256 totalRarity = 0;
        if(attrType == 0){
            genSeries[seriesId].attrType.increment(); // should do +=
            attrType = genSeries[seriesId].attrType.current();
        }else {
            require(abi.encodePacked(genSeries[seriesId].attributes[attrType][1].name).length != 0,"attrType doesn't exists, please pass attrType=0 for new attrType");
        }
        require(name.length == uri.length && name.length == rarity.length, "attributes length mismatched");
        Counters.Counter storage _attrId = genSeries[seriesId].attrId; // need to reset so rarity sum calc could be exact to avoid rarity issues
        _attrId.reset(); // reseting attrIds to overwrite
        // delete genSeries[seriesId].attributes[attrType];
        uint256 from = _attrId.current() + 1;
        for (uint256 index = 0; index < name.length; index++) {
            totalRarity = totalRarity + rarity[index];
            require( totalRarity <= 100, "Rarity sum of attributes can't exceed 100");
            _attrId.increment();
            genSeries[seriesId].attributes[attrType][_attrId.current()] = Attribute(name[index], uri[index], rarity[index]);
        }

        require( totalRarity == 100, "Rarity sum of attributes shoud be equal to 100");
        emit AttributesAdded(seriesId, attrType,from, _attrId.current());
    }
/** 
    @dev function to start new Generative Series
        @param name - name of the series
        @param seriesURI - series metadata tracking URI
        @param boxName - name of the boxes to be created in this series
        @param boxURI - blindbox's URI tracking its metadata
        @param startTime - start time of the series, (from whom its boxes will be available to get bought)
        @param endTime - end time of the series, (after whom its boxes will not be available to get bought)

    */
    function generativeSeries(address bCollection, string memory name, string memory seriesURI, string memory boxName, string memory boxURI, uint256 startTime, uint256 endTime, uint256 royalty) onlyOwner internal {
        require(startTime < endTime, "invalid series endTime");
        seriesIdsByCollection[bCollection][true].push(generativeSeriesId.current());
        genCollection[generativeSeriesId.current()] = bCollection;
        genSeries[generativeSeriesId.current()].name = name;
        genSeries[generativeSeriesId.current()].seriesURI = seriesURI;
        genSeries[generativeSeriesId.current()].boxName = boxName;
        genSeries[generativeSeriesId.current()].boxURI = boxURI;
        genSeries[generativeSeriesId.current()].startTime = startTime;
        genSeries[generativeSeriesId.current()].endTime = endTime;

        emit NewGenSeries( generativeSeriesId.current(), name, startTime, endTime);
    }
    function setExtraParamsGen(uint256 _baseCurrency, uint256[] memory allowedCurrecny, address _bankAddress, uint256 boxPrice, uint256 maxBoxes, uint256 perBoxNftMint) internal {
        baseCurrencyGen[generativeSeriesId.current()] = _baseCurrency;
        _allowedCurrenciesGen[generativeSeriesId.current()] = allowedCurrecny;
        bankAddressGen[generativeSeriesId.current()] = _bankAddress;
        genSeries[generativeSeriesId.current()].price = boxPrice;
        genSeries[generativeSeriesId.current()].maxBoxes = maxBoxes;
        genSeries[generativeSeriesId.current()].perBoxNftMint = perBoxNftMint;
    }
    /** 
    @dev utility function to mint Generative BlindBox
        @param seriesId - id of Generative Series whose box to be opened
    @notice given series should not be ended or its max boxes already minted.
    */
    function mintGenBox(uint256 seriesId) private {
        require(genSeries[seriesId].endTime >= block.timestamp, "series ended");
        require(genSeries[seriesId].maxBoxes > genSeries[seriesId].boxId.current(),"max boxes minted of this series");
        genSeries[seriesId].boxId.increment(); // incrementing boxCount minted
        _boxId.increment(); // incrementing to get boxId

        boxesGen[_boxId.current()].name = genSeries[seriesId].boxName;
        boxesGen[_boxId.current()].boxURI = genSeries[seriesId].boxURI;
        boxesGen[_boxId.current()].series = seriesId;
        boxesGen[_boxId.current()].countNFTs = genSeries[seriesId].perBoxNftMint;
       
        // uint256[] attributes;    // attributes setting in another mapping per boxId. note: series should've all attributes [Done]
        // uint256 attributesRarity; // rarity should be 100, how to ensure ? 
                                    //from available attrubets fill them in 100 index of array as per their rarity. divide all available rarites into 100
        emit BoxMintGen(_boxId.current(), seriesId);

    }
     modifier validateCurrencyTypeGen(uint256 seriesId, uint256 currencyType, bool isPayable) {
        bool isValid = false;
        uint256[] storage allowedCurrencies = _allowedCurrenciesGen[seriesId];
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
    @dev function to buy Generative BlindBox
        @param seriesId - id of Generative Series whose box to be bought
    @notice given series should not be ended or its max boxes already minted.
    */
    function buyGenerativeBox(uint256 seriesId, uint256 currencyType) validateCurrencyTypeGen(seriesId, currencyType, false) internal {
        require(abi.encode(genSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(genSeries[seriesId].maxBoxes > genSeries[seriesId].boxId.current(),"boxes sold out");
        mintGenBox(seriesId);
       token = USD;
        
        uint256 price = dex.calculatePrice(genSeries[seriesId].price , baseCurrencyGen[seriesId], currencyType, 0, address(this), address(this));
        // if(currencyType == 0){
            price = price / 1000000000000;
        // }
        // escrow alia
        token.transferFrom(msg.sender, bankAddressGen[seriesId], price);
        genBoxOwner[_boxId.current()] = msg.sender;

        emit BuyBoxGen(_boxId.current(), seriesId);
    }
    function buyGenBoxPayable(uint256 seriesId) validateCurrencyTypeGen(seriesId,1, true) internal {
        require(abi.encode(genSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(genSeries[seriesId].maxBoxes > genSeries[seriesId].boxId.current(),"boxes sold out");
        uint256 before_bal = MATIC.balanceOf(address(this));
        MATIC.deposit{value : msg.value}();
        uint256 after_bal = MATIC.balanceOf(address(this));
        uint256 depositAmount = after_bal - before_bal;
        uint256 price = dex.calculatePrice(genSeries[seriesId].price , baseCurrencyGen[seriesId], 1, 0, address(this), address(this));
        require(price <= depositAmount, "NFT 108");
        chainTransfer(bankAddressGen[seriesId], 1000, price);
        if(depositAmount - price > 0) chainTransfer(msg.sender, 1000, (depositAmount - price));
        mintGenBox(seriesId);
        // transfer box to buyer
        genBoxOwner[_boxId.current()] = msg.sender;

        emit BuyBoxGen(_boxId.current(), seriesId);
    }
    function chainTransfer(address _address, uint256 percentage, uint256 price) internal {
      address payable newAddress = payable(_address);
      uint256 initialBalance;
      uint256 newBalance;
      initialBalance = address(this).balance;
      MATIC.withdraw(SafeMath.div(SafeMath.mul(price,percentage), 1000));
      newBalance = address(this).balance.sub(initialBalance);
    //   newAddress.transfer(newBalance);
    (bool success, ) = newAddress.call{value: newBalance}("");
    require(success, "Failed to send Ether");
  }
/** 
    @dev function to open Generative BlindBox
        @param boxId - id of blind box to be opened
    @notice given box should not be already opened.
    */
    function openGenBox(uint256 boxId) internal {
        require(genBoxOwner[boxId] == msg.sender, "Box not owned");
        require(!boxesGen[boxId].isOpened, "Box already opened");
        _openGenBox(boxId);

        emit BoxOpenedGen(boxId);

    }
    event Msg(string msg);
    event Value(uint256 value);
    /** 
    @dev utility function to open Generative BlindBox
        @param boxId - id of blind box to be opened
    @notice given box should not be already opened.
    */
    function _openGenBox(uint256 boxId) private {
        uint256 sId = boxesGen[boxId].series;
        uint256 attrType = genSeries[sId].attrType.current();
        
        uint256 rand = getRand(); // should get random number within range of 100
        // NFT[] storage nft = NFT[](boxesGen[boxId].countNFTs);
        uint256 i;
        uint256 j;
        bytes32 combHash;
        uint256 rand1;
        for ( i = 1; i <= boxesGen[boxId].countNFTs; i++) {
            emit Msg("into NFT loop");
            combHash = bytes32(0); // reset combHash for next iteration of possible NFT
            // combHash = keccak256(abi.encode(sId,boxId)); // to keep combHash of each box unique [no needed, as list is per series]
            
            for ( j = 1; j <= attrType; j++){
                // select one random attribute from each attribute type
                // set in mapping against boxId
                emit Msg("into attrType loop");
                rand1 = uint256(keccak256(abi.encodePacked(block.coinbase, rand, msg.sender, i,j))).mod(100); // to keep each iteration further randomize and reducing fee of invoking VRF on each iteration.
                emit Value(rand1);
                nftsToMint[boxId][i][j] = getRandAttr(sId, boxId, j, rand1);
                // nftsToMint[i].attribute[j] = getRandAttr(sId, boxId, j);
                // generate hash of comb decided so far
                combHash = keccak256(abi.encode(combHash, nftsToMint[boxId][i][j])); // TODO: need to test if hash appending work same like hashing with all values at once. [DONE]
            }
                // bytes32 comb = keccak256(abi.encode())
            // check if selected attr comibination is blacklisted
            if( isBlackListed(sId, combHash)){
                // same iteration should run again
                i = i - 1;
                j = j - 1;
                rand = getRand(); // getting new random number to skip blacklisted comb on same iteration.
                // delete nftsToMint[boxId][i]; // deleting blacklisted comb NFT [need to delete each j's entry] TODO: what if left as it is to be replaced in next iteration with same i
            }
        }

        boxesGen[boxId].isOpened = true;
    }

    /** 
    @dev utility function to get Random attribute of given attribute Type based on attributes rarities.
        @param seriesId - id of generative series
        @param boxId - id of blindbox whose
        @param attrType - attribute type whose random attribute to be selected
        @param rand - random number on whose basis random attribute to be selected
    */
    function getRandAttr(uint256 seriesId, uint256 boxId, uint256 attrType, uint256 rand) private returns(uint256) {
        uint256[] memory attrs = new uint256[](100);
        Attribute memory attr;
        uint256 occurence;
        uint256 i = 0;
        // populate attributes in array as per their rarity
        for (uint256 attrId = 1; attrId <= genSeries[seriesId].attrId.current(); attrId++) {
            attr = genSeries[seriesId].attributes[attrType][attrId];
            // occurence = getOccurency(attr, attrType);
            occurence = attr.rarity;
            for (uint256 index = 0; index < occurence; index++) {
                attrs[i] = attrId;
                i++;
                if( i > rand ){
                    break;
                }
            }
        }
        // generate rand num through VRF out of 100 (size of array) can increase size or decrase based on attributes quantity
        // pic that index's attributeId and return
        // emit Attr(attrType, attrs[rand]);
        return attrs[rand];
    }

    /** 
    @dev function to check is given combination of attributes of specific series is blacklisted or not
        @param seriesId series Id whose blacklist to be checked against given combHash
        @param combHash hash of attributes combination which is to be checked
    */
    function isBlackListed(uint256 seriesId, bytes32 combHash) public view returns(bool) {
        return genSeries[seriesId].blackList[combHash];
    }
    /** 
    @dev function to get hash of given attributes combination.
        @param seriesId series Id whose attributes combination
        @param boxId hash of attributes combination which is to be checked
    */
    function getCombHash(uint256 seriesId, uint256 boxId, uint256[] memory attrTypes, uint256[] memory attrIds) public pure returns(bytes32) {
        bytes32 combHash = bytes32(0);
        // for (uint256 i = 0; i < attrTypes.length; i++) {
            for (uint256 j = 0; j < attrIds.length; j++) {
                combHash = keccak256(abi.encode(combHash,attrIds[j]));
            }
            
        // }
        return combHash;
    }
/** 
    @dev function to blacklist given attributes combination.
        @param seriesId series Id whose attributes combination to be blacklisted
        @param combHash hash of attributes combination to be blacklisted
        @param flag flag to blacklist or not.
    */
    function blackListAttribute(uint256 seriesId, bytes32 combHash, bool flag) public onlyOwner {
        genSeries[seriesId].blackList[combHash] = flag;
        emit BlackList(seriesId, combHash, flag);
    }
   /** 
    @dev function to mint NFTs by sumbitting finalized URIs of comibation attributes, randomly calculated at the time of box was opened.
        @param boxId boxId whose randomly calculated NFTs to be minted
        @param uris Generated array of URIs to be minted.
    @notice only owner of the contract can trigger this function
    */
    function mintGenerativeNFTs(address collection, uint256 boxId, string[] memory uris) public onlyOwner {
        require(nftsToMint[boxId][1][1] > 0, "boxId isn't opened");
        require(boxesGen[boxId].countNFTs == uris.length, "insufficient URIs to mint");
         for (uint256 i = 0; i < uris.length; i++) {
            dex.mintWithCollection(collection, genBoxOwner[boxId], uris[i], genseriesRoyalty[boxesGen[boxId].series]);
         }
         uint256 countNFTs = boxesGen[boxId].countNFTs;
         delete boxesGen[boxId]; // deleting box to avoid duplicate NFTs mint
         emit NFTsMinted(boxId, genBoxOwner[boxId], countNFTs);
    }
 /** 
    @dev function to mint NFTs by sumbitting finalized URIs of comibation attributes, randomly calculated at the time of box was opened.
        @param seriesId ID of series whose attributes to be fetched.
        @param attrType attribute Type of which attributes to be fetched.
        @param attrId attribute ID to be fetched.
    */
    function getAttributes(uint256 seriesId, uint256 attrType, uint256 attrId) public view returns(Attribute memory){
        return genSeries[seriesId].attributes[attrType][attrId];
    }
    
    // events
    event NewGenSeries(uint256 indexed seriesId, string name, uint256 startTime, uint256 endTime);
    event BoxMintGen(uint256 boxId, uint256 seriesId);
    event AttributesAdded(uint256 indexed seriesId, uint256 indexed attrType, uint256 from, uint256 to);
    event BuyBoxGen(uint256 boxId, uint256 seriesId);
    event BoxOpenedGen(uint256 indexed boxId);
    event BlackList(uint256 indexed seriesId, bytes32 indexed combHash, bool flag);
    event NFTsMinted(uint256 indexed boxId, address owner, uint256 countNFTs);
    

}