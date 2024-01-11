// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenerativeBB.sol";

contract NonGenerativeBB is GenerativeBB {
 using Counters for Counters.Counter;
    using SafeMath for uint256;
    
   

    function airDropBoxNonGenAdmin(uint256 seriesId, address to, string memory ownerId, address collection) onlyOwner public {
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
        nonGenBoxOwner[_boxId.current()] = to;
        uint256 boxId = _boxId.current();
        uint256 from;
        uint256 toIndex;
        (from, toIndex) =dex.mintBlindbox(collection, to, boxesNonGen[boxId].countNFTs, bankAddress[boxesNonGen[boxId].series], nonGenseriesRoyalty[boxesNonGen[boxId].series], ownerId);   // this function should be implemented in DEX contract to return (uint256, uint256) tokenIds, for reference look into Collection.sol mint func. (can be found at Collection/Collection.sol of same repo)
        boxesNonGen[boxId].isOpened = true;
        emit NonGenNFTsMinted(boxesNonGen[boxId].series, boxId, from, toIndex, 0, boxesNonGen[boxId].countNFTs);
        emit BuyBoxNonGen(_boxId.current(), seriesId, nonGenSeries[seriesId].price, 0, nonGenSeries[seriesId].collection, to, baseCurrency[seriesId], 0);
   
    }
    
    // events
    event NewNonGenSeries(uint256 indexed seriesId, string name, uint256 startTime, uint256 endTime);
    event BoxMintNonGen(uint256 boxId, uint256 seriesId);
    // event AttributesAdded(uint256 indexed boxId, uint256 indexed attrType, uint256 fromm, uint256 to);
    event URIsAdded(uint256 indexed boxId, uint256 from, uint256 to, string[] uris, string[] name, uint256[] rarity);
    event BuyBoxNonGen(uint256 boxId, uint256 seriesId, uint256 orignalPrice, uint256 currencyType, string collection, address from,uint256 baseCurrency, uint256 calculated);
    event BoxOpenedNonGen(uint256 indexed boxId);
    event NonGenNFTMinted(uint256 indexed boxId, uint256 tokenId, address from, address collection, uint256 uriIndex );
    // event BlackList(uint256 indexed seriesId, bytes32 indexed combHash, bool flag);
    event NonGenNFTsMinted(uint256 seriesId, uint256 indexed boxId, uint256 from, uint256 to, uint256 rand, uint256 countNFTs);
    

}