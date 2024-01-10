// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BlindboxStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract Utils is Ownable, BlindboxStorage{
    
    using SafeMath for uint256;

    constructor() {
       

    }
   
    function updateDexAddress(address _add) onlyOwner public {
    dex = IDEX(_add);
  }

   
   function addWhiteListUsers(bytes32[] memory users, uint256 seriesId) onlyOwner public {
    for(uint256 i = 0; i<users.length; i++){
      _whitelisted[users[i]][seriesId] = true;
    }
  }

  function removeWhiteListUsers(bytes32[] memory users, uint256 seriesId) onlyOwner public {
      for(uint256 i = 0; i<users.length; i++){
      _whitelisted[users[i]][seriesId] = false;
    }
  }

     function addCryptoWhiteListUser(address[] memory _addresses, uint256 seriesId) onlyOwner public {
      for(uint256 i =0; i< _addresses.length; i++){
          crypoWhiteList[_addresses[i]][seriesId] = true;
      }
   }

   function addNonCryptoWhiteListUser(string[] memory ownerIds, uint256 seriesId) onlyOwner public {
      for(uint256 i =0; i< ownerIds.length; i++){
          nonCryptoWhiteList[ownerIds[i]][seriesId] = true;
      }
   }

   function removeCryptoWhiteListUser(address[] memory _addresses, uint256 seriesId) onlyOwner public {
      for(uint256 i =0; i< _addresses.length; i++){
          crypoWhiteList[_addresses[i]][seriesId] = false;
      }
   }

   function removeNonCryptoWhiteListUser(string[] memory ownerIds, uint256 seriesId) onlyOwner public {
      for(uint256 i =0; i< ownerIds.length; i++){
          nonCryptoWhiteList[ownerIds[i]][seriesId] = false;
      }
   }

  function isSeriesWhiteListed(uint256 seriesId) public view returns(bool) {
    return _isWhiteListed[seriesId];
  }
   function isUserWhiteListed(bytes32 user, uint256 seriesId) public view returns(bool) {
    return _whitelisted[user][seriesId];
  }

  
    
}