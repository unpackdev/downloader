// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./SkullPunksLogic.sol";

contract SkullpunksXG is ERC721URIStorage,SkullPunksLogic{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  modifier checkTotalMint(){
    require(_tokenIds.current() <= 4999,'The limit of SkullpunksXG to be minted has reached.');
    _;
  }
  constructor(address payable wallet,uint256 price) 
  ERC721("Skullpunks-Xg", "SP-Xg")
  SkullPunksLogic(){
    require(updatePrice(price), "unable to update price");
    require(updateWallet(wallet),"unable to update wallet");
    // OG array length
    uint OgLength = OGs.length;
    for (uint i=0; i < OgLength; i++) {
      //og
      address og = OGs[i];
      require(addMintAllowance(og, 1),"was not able to load allowance");
    }
  }
  
  function mint(string memory tokenURI,uint256 toAllow) public payable checkTotalMint() returns (uint256){
    _tokenIds.increment();
    uint256 toPay       = getPrice();
    uint256 edition     = _tokenIds.current();
    //allow people to mint during flashsale without affecting their free passes
    bool initalMintStatus = isInitialMint(msg.sender);
    uint256 _allowance    = getMintAllowance(msg.sender);
    if(_allowance > 0){
      toPay = 0;
      //inital mint has been updated check and withdraw from mint allowance
      require(reduceMintAllowance(msg.sender),"This senders allowance cannot be updated at this time");
    }

    if(initalMintStatus == false){//if initial mint has not been updated
      require(initialMintAllowance(msg.sender,toAllow),"Allowance update error");
    } 

    //requires payment
    require(msg.value >= toPay,"Amount not equal to price");
    if(msg.value > 0){
        forwardEth();
    }

    _mint(msg.sender, edition);
    _setTokenURI(edition, tokenURI);
    return edition;
  }
  function tokenCursor() public view returns (uint256){
    return _tokenIds.current();
  }

}
