
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: Squeebo                     *
 * @team:   X-11                        *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./Delegated.sol";
import "./ERC721EnumerableLite.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

contract m00sik is Delegated, ERC721EnumerableLite, PaymentSplitter {
  using Strings for uint;

  uint public MAX_ORDER  = 20;
  uint public MAX_SUPPLY = 3760;
  uint public PRICE      = 0.027 ether;

  bool public isActive   = false;

  string private _baseTokenURI = 'https://herodev.mypinata.cloud/ipfs/QmTsbSVryj7WfWdWQ2RkUEaDPyJd4Z5SvdnhFvHFJYyAUw/';
  string private _tokenURISuffix = '.json';

  address[] private addressList = [
    0x47a17951A78653639d31d351ce89B57397dDb1e2,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];
  uint[] private shareList = [
    90,
    10
  ];

  constructor()
    Delegated()
    ERC721B("m00sik", "MSK")
    PaymentSplitter(addressList, shareList){
  }

  //external
  fallback() external payable {}

  function mint( uint quantity ) external payable {
    require( isActive,                      "Sale is not active"        );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    require( msg.value >= PRICE * quantity, "Ether sent is not correct" );

    uint256 supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }

  //delegated
  function gift(uint[] calldata quantity, address[] calldata recipient) external onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint256 supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _safeMint( recipient[i], supply++, "" );
      }
    }
  }

  function setActive(bool isActive_) external onlyDelegates{
    require( isActive != isActive_, "New value matches old" );
    if( isActive != isActive_ )
      isActive = isActive_;
  }

  function setMaxOrder(uint maxOrder) external onlyDelegates{
    require( MAX_ORDER != maxOrder, "New value matches old" );
    MAX_ORDER = maxOrder;
  }

  function setPrice(uint price ) external onlyDelegates{
    require( PRICE != price, "New value matches old" );
    PRICE = price;
  }

  function setBaseURI(string calldata newBaseURI, string calldata newSuffix) external onlyDelegates{
    _baseTokenURI = newBaseURI;
    _tokenURISuffix = newSuffix;
  }

  //onlyOwner
  function setMaxSupply(uint maxSupply) external onlyOwner{
    require( MAX_SUPPLY != maxSupply, "New value matches old" );
    require(maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }

  //public
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
  }
}
