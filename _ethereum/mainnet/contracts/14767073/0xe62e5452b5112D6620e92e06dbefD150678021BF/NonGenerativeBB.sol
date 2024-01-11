// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenerativeBB.sol";

contract NonGenerativeBB is GenerativeBB {
 using Counters for Counters.Counter;
    using SafeMath for uint256;
   
     function buyNonGenBoxPayable(uint256 seriesId, address collection, bytes32 user)  internal {
      require(!_isWhiteListed[seriesId] || crypoWhiteList[msg.sender][seriesId], "not authorize");
        require(abi.encodePacked(nonGenSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(nonGenSeries[seriesId].maxBoxes > nonGenSeries[seriesId].boxId.current(),"boxes sold out");
        uint256 depositAmount = msg.value;
        uint256 price = nonGenSeries[seriesId].price;
        require(price <= depositAmount, "NFT 108");
        // transfer box to buyer
        nonGenBoxOwner[_boxId.current()] = msg.sender;
        mintNonGenNFT(seriesId, 1, price, collection, "");
        // chainTransfer(bankAddress[seriesId], price);
        payable(bankAddress[seriesId]).call{value: price}("");
        if(depositAmount - price > 0) payable(msg.sender).call{value: (depositAmount - price)}(""); //chainTransfer(msg.sender, (depositAmount - price));
      }
  
    function mintNonGenNFT(uint256 seriesId, uint256 currencyType, uint256 price, address collection, string memory ownerId) private {
        require(_boxesCrytpoUser[msg.sender][seriesId] < _perBoxUserLimit[seriesId], "Limit reach" );
        require(nonGenSeries[seriesId].startTime <= block.timestamp, "series not started");
        require(nonGenSeries[seriesId].endTime >= block.timestamp, "series ended");
        require(nonGenSeries[seriesId].maxBoxes > nonGenSeries[seriesId].boxId.current(),"max boxes minted of this series");
       
        _boxesCrytpoUser[msg.sender][seriesId]++; 
        nonGenSeries[seriesId].boxId.increment(); 
        (uint256 from, uint256 to) =BNFT(collection).mint( msg.sender, nonGenSeries[seriesId].perBoxNftMint);   // this function should be implemented in DEX contract to return (uint256, uint256) tokenIds, for reference look into Collection.sol mint func. (can be found at Collection/Collection.sol of same repo)
        emit NonGenNFTsMinted(seriesId, 0, from, to, 0, nonGenSeries[seriesId].perBoxNftMint);
        emit MintBlindBox(seriesId, msg.sender, from, to, nonGenSeries[seriesId].perBoxNftMint, collection);
        emit BuyBoxNonGen(_boxId.current(), seriesId, nonGenSeries[seriesId].price, currencyType, nonGenSeries[seriesId].collection, msg.sender, baseCurrency[seriesId], price);
    }
// events
    event BoxMintNonGen(uint256 boxId, uint256 seriesId);
    // event AttributesAdded(uint256 indexed boxId, uint256 indexed attrType, uint256 fromm, uint256 to);
    event BuyBoxNonGen(uint256 boxId, uint256 seriesId, uint256 orignalPrice, uint256 currencyType, string collection, address from,uint256 baseCurrency, uint256 calculated);
    event BoxOpenedNonGen(uint256 indexed boxId);
   // event BlackList(uint256 indexed seriesId, bytes32 indexed combHash, bool flag);
    event NonGenNFTsMinted(uint256 seriesId, uint256 indexed boxId, uint256 from, uint256 to, uint256 rand, uint256 countNFTs);
    event MintBlindBox(uint256 seriesId, address buyer, uint256 from, uint256 to,  uint256 countNFTs, address collection);
    

}