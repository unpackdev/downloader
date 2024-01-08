
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./Delegated.sol";
import "./ERC721EnumerableLite.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

contract MetaElfMania is Delegated, ERC721EnumerableLite, PaymentSplitter {
  using Strings for uint;

  uint public MAX_ORDER  = 100;
  uint public MAX_SUPPLY = 1225;
  uint public PRICE      = 0.025 ether;

  bool public isActive   = false;

  string private _baseTokenURI = '';
  string private _tokenURISuffix = '';

  address[] private addressList = [
    0xA6e091846f2a8bb6a56f43a0aDce07Ccd7eb4E24,
    0xcA9DEAc36C4E786342AB60268756D3c45A95D01E,
    0x292A3708ae30Ac205EB94eAe7ec861dFB0ed07b4,
    0x5402945b1a28342437AD8468Ada8C9E4F7907dCE,
    0x60Cc5C94794C9f88433abB9513a993450a051767,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];
  uint[] private shareList = [
    320,
    125,
    125,
    125,
    125,
    180
  ];

  constructor()
    ERC721B("Meta Elf Mania", "MEM", 0)
    PaymentSplitter( addressList, shareList ){
  }

  //external

  fallback() external payable {}

  function mint( uint quantity ) external payable {
    require( isActive,                      "Sale is not active"        );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    require( msg.value >= PRICE * quantity, "Ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++ );
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
        _mint( recipient[i], supply++ );
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
