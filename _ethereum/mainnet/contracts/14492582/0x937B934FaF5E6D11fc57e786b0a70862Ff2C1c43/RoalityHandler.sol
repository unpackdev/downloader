// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IERC165.sol";
import "./IRoality.sol";

library RoalityHandler {

  modifier hasRoality(address nftContract) {
    require(isSupportRoality(nftContract));
    _;
  }

  function isSupportRoality(address nftContract) 
    internal 
    view 
    returns (bool) {
    
      return IERC165(nftContract)
        .supportsInterface(
          type(IRoality).interfaceId
        );

    }

  function roalityAccount(address nftContract) 
    internal 
    view 
    hasRoality(nftContract) 
    returns (address) {

      return IRoality(nftContract).roalityAccount();

    }

  function roality(address nftContract)
    internal
    view
    hasRoality(nftContract) 
    returns (uint256) {

      return IRoality(nftContract).roality();

    }

  function setRoalityAccount(address nftContract, address account)
    internal
    hasRoality(nftContract) {

      IRoality(nftContract).setRoalityAccount(account);

    }

  function setRoality(address nftContract, uint256 thousandths)
    internal
    hasRoality(nftContract) {

      IRoality(nftContract).setRoality(thousandths);
      
    }

}