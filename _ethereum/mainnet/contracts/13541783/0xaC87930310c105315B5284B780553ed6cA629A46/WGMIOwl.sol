
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: Squeebo                     *
 * @team:   X-11                        *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./ERC721B.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract WGMIOwl is Ownable, ERC721B {
  using Strings for uint;

  uint public MAX_SUPPLY = 3333;

  uint public price      = 0.065 ether;
  bool public isActive   = false;
  uint public maxOrder   = 15;

  string private _baseTokenURI = '';
  string private _tokenURISuffix = '';

  constructor()
    ERC721B("WGMI Owls Kingdom", "WGMI"){
  }

  //external

  fallback() external payable {}

  receive() external payable {}

  function mint( uint numberOfTokens ) external payable {
    require( isActive,                            "Sale must be active to mint owl" );
    require( numberOfTokens <= maxOrder,          "Can only mint 15 tokens at a time" );
    require( msg.value >= price * numberOfTokens, "Ether value sent is not correct" );

    uint256 supply = _owners.length;
    require( supply + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply of OWLS" );
    for(uint i = 0; i < numberOfTokens; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }


  //delegated
  function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
    require(quantity.length == recipient.length, "Must provide equal quantity and recipient" );

    uint totalQuantity = 0;
    uint256 supply = _owners.length;
    for(uint i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order would exceed max supply of OWLS" );
    delete totalQuantity;

    for(uint i = 0; i < recipient.length; ++i){
      for(uint j = 0; j < quantity[i]; ++j){
        _safeMint( recipient[i], supply++, "" );
      }
    }
  }

  function setActive(bool isActive_) external onlyOwner{
    if( isActive != isActive_ )
      isActive = isActive_;
  }

  function setMaxOrder(uint maxOrder_) external onlyOwner{
    if( maxOrder != maxOrder_ )
      maxOrder = maxOrder_;
  }

  function setPrice(uint price_ ) external onlyOwner{
    if( price != price_ )
      price = price_;
  }

  function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyOwner{
    _baseTokenURI = _newBaseURI;
    _tokenURISuffix = _newSuffix;
  }

  //onlyOwner
  function setMaxSupply(uint maxSupply) external onlyOwner{
    if( MAX_SUPPLY != maxSupply ){
      require(maxSupply >= _owners.length, "Specified supply is lower than current balance" );
      MAX_SUPPLY = maxSupply;
    }
  }

  function withdraw() external onlyOwner {
      require(address(this).balance >= 0, "No funds available");
      Address.sendValue(payable(owner()), address(this).balance);
  }

  //public
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
  }
}
