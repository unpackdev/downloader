// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: BriThaCryptoGuy             *
 *          Blimpie by squeebo_nft      *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./Delegated.sol";
import "./ERC721EnumerableLite.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

contract OddFcknMonsters is Delegated, ERC721EnumerableLite, PaymentSplitter {
  using Strings for uint;

  uint public MAX_ORDER  = 100;
  uint public MAX_SUPPLY = 5000;
  uint public PRICE      = 0.03 ether;

  bool public isActive   = false; 

  string private _baseTokenURI = '';
  string private _tokenURISuffix = '';

  address[] private addressList = [
    0x581abFe25aaA7E876E838c81465fF62813a5d488,
    0x327EC442254e9Dc1dd91c2156725e0A523C06850,
    0xbFB7FEa930CE5933Ca513aE049492dD73a660dac,
    0xAe6b66ee53bd9C8689656b18fB51Df9eC32CEF29,
    0x849f4A2Aa2553d062C3df30bc78e7eceF7F2df6B
  ];
  uint[] private shareList = [
    25,
    25,
    20,
    15,
    15
  ];

  constructor()
    ERC721B("Odd FcKn Monsters", "OFM", 1)
    PaymentSplitter( addressList, shareList ){      
  }

  //external

  fallback() external payable {}

  function mint( uint quantity ) external payable {
    require( isActive,                      "Sale is not active"        );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    if (msg.sender != owner()) {
      require( msg.value >= PRICE * quantity, "Ether sent is not correct" );
    }    

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply + (i+1));
    }
  }

  //onlyDelegates
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity < MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i], supply + (i+1));
      }
    }
  }

  function setActive(bool isActive_) external onlyDelegates{
    require( isActive != isActive_, "New value matches old" );
    isActive = isActive_;
  }

  function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyDelegates{
    _baseTokenURI = _newBaseURI;
    _tokenURISuffix = _newSuffix;
  }

  function setMaxOrder(uint maxOrder) external onlyDelegates{
    require( MAX_ORDER != maxOrder, "New value matches old" );
    MAX_ORDER = maxOrder;
  }

  function setPrice(uint price ) external onlyDelegates{
    require( PRICE != price, "New value matches old" );
    PRICE = price;
  }


  //onlyOwner
  function setMaxSupply(uint maxSupply) external onlyOwner{
    require( MAX_SUPPLY != maxSupply, "New value matches old" );
    require( maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }


  //public
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
  }

  function _mint(address to, uint tokenId) internal virtual override {
    _owners.push(to);
    emit Transfer(address(0), to, tokenId);
  }
}
