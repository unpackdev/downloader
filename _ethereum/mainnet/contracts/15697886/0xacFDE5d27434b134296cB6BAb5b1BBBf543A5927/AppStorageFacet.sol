// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./LibAppStorage.sol";
import "./IAppStorage.sol";
///@author @0xSimon_

contract AppStorageFacet is Ownable {

    function initializeAppStorage(address ingotTokenAddress,address koboldAddress,address titanAddress) external onlyOwner{
        AppStorage storage ds = LibAppStorage.appStorage();
        ds.ingotTokenAddress = ingotTokenAddress;
        ds.koboldAddress = koboldAddress;
        ds.titanAddress = titanAddress;
    }
    function setIngotTokenAddress(address ingotTokenAddress) external onlyOwner{
        LibAppStorage.setIngotTokenAddress(ingotTokenAddress);
    }
      function setKoboldAddress(address koboldAddress) external onlyOwner{
        LibAppStorage.setKoboldAddress(koboldAddress);
    }
      function setTitanAddress(address titanAddress) external onlyOwner{
        LibAppStorage.setTitanAddress(titanAddress);
    }
    function getIngotTokenAddress() external view returns(address) {
     return LibAppStorage.getIngotTokenAddress();
    }
     function getKoboldAddress() external view returns(address) {
      return LibAppStorage.getKoboldAddress();
    }
     function getTitanAddress() external view returns(address) {
       return LibAppStorage.getTitanAddress();
    }
}