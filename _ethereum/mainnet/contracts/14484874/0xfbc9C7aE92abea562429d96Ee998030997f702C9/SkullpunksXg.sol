// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";

import "./SkullPunksLogic.sol";

contract SkullpunksXG is ERC721URIStorage,SkullPunksLogic{


  constructor(address payable wallet,uint256 price) 
  ERC721("Skullpunks-Xg", "SP-Xg")
  SkullPunksLogic(){
    require(updatePrice(price), "unable to update price");
    require(updateWallet(wallet), "unable to update wallet");
 
  }
  
  function mint(string memory tokenURI, uint256 edition,uint256 toAllow) public payable returns (bool){
    
    uint256 allowance = getFreeMint(msg.sender);
    
    //requires payment for users with no passes
    if(allowance < 1){
      require(msg.value >= price, "Amount not equal to price");
    }
    
    require(!getEditionStatus(edition), "This edition has already been transformed");
    require(updateEditionLog(edition),"This edition cannot be updated at this time");
    
    //allow people to mint during flashsale without affecting their free passes
    if(!isFlash()){
      require(initialMintAllowance(msg.sender,toAllow),"Allowance update error");
      require(updateMintAllowance(msg.sender),"This senders allowance cannot be updated at this time");
    
    }
    
    if(msg.value > 0){
        forwardEth();
    } 
    _mint(msg.sender, edition);
    _setTokenURI(edition, tokenURI);
    

    return true;
  }

}
