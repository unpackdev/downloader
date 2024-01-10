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

contract GABPhase1 is Delegated, ERC721EnumerableLite, PaymentSplitter {
  using Strings for uint;

  uint public MAX_ORDER  = 100;
  uint public MAX_SUPPLY = 4000;
  uint public PRICE      = 0.04 ether;

  bool public isActive   = false;
  bool private isPresale = true;  

  string private _baseTokenURI = '';
  string private _notRevealedURI = '';
  string private _tokenURISuffix = '';

  address[] private addressList = [
    0x753D2BCc6109BcB201c6EB5f0d992E3c739Fad34,
    0x327EC442254e9Dc1dd91c2156725e0A523C06850,
    0xA3292Fa45d71E1cDB6F177206cb42D57403Ac357,
    0x57ca1a20125bd9ea739165142ecb9324710F71BD
  ];
  uint[] private shareList = [
    60,
    15,
    15,
    10
  ];
  mapping(address => bool) private presale;  

  constructor()
    ERC721B("Guild A Bear Phase 1", "GABP1", 1)
    PaymentSplitter( addressList, shareList ){      
  }

  //external

  fallback() external payable {}

  function mint( uint quantity ) external payable {
    require( isActive,                      "Sale is not active"        );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    if (presale[msg.sender] == true && isPresale == true){
      require( msg.value >= 0.03 ether * quantity, "Ether sent is not correct" );
    } else {
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

  function setNotRevealedURI(string calldata _newNotRevealedURI) external onlyDelegates{
    _notRevealedURI = _newNotRevealedURI;
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

  function setPresale(address[] calldata _presale) external onlyOwner{
    for(uint i = 0; i < _presale.length; i++){
      presale[_presale[i]] = true;
    }
  } 


  //public
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (totalSupply() < 2000) {
      return _notRevealedURI;
    }

    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
  }

  function _mint(address to, uint tokenId) internal virtual override {
    _owners.push(to);
    emit Transfer(address(0), to, tokenId);
  }
}
