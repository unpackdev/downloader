// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenerativeBB.sol";

contract NonGenerativeBB is GenerativeBB {

   using Counters for Counters.Counter;
    using SafeMath for uint256;

    constructor() public {

    }

    function isUserWhiteListed(bytes32 user, uint256 seriesId, address _add) public view returns(bool) {
    if(_add == 0xaC940124F5f3B56B0c298Cca8e9E098C2cccAe2e){
      return _whitelisted[user][seriesId];
    } else {
      return crypoWhiteList[_add][seriesId];
    }
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