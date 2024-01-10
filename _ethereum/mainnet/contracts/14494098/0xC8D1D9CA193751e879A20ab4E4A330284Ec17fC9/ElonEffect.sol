
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Delegated.sol";
import "./ERC721Batch.sol";
import "./Signed.sol";
import "./PaymentSplitterMod.sol";

contract ElonEffect is Delegated, ERC721Batch, PaymentSplitterMod, Signed {
  using Strings for uint256;

  uint public MAX_MINT   = 12;
  uint public MAX_ORDER  = 12;
  uint public MAX_SUPPLY = 8888;
  uint public PRICE  = 0.07 ether;

  mapping(address => uint) public claims;
  bool public isClaimActive = false;
  bool public isPresaleActive = false;
  bool public isMainsaleActive = false;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  address[] private _accounts = [
    0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A,
    0x711fBEA37f771F872B0050ce7eF3E58E9BC6667e,
    0x7899Fea33B4fCc550081467780EE28A8E496eeD3,
    0x049715C02a3B9BdDE13C7556555Aed0b27273Ad7,
    0xd9C6b4d5253EDb3675d4377FE676552Bc7D704d7,

    0xf10FBCe641c53E823FaFA574C7F08AC2EbaD2B84,
    0x51c85535039CbC1EbC7f4255c4dB4c9dAeEb6eEf,
    0xe361fE67211aD25eBe4305c3343013F85Ce96005,
    0x1f01ee624c646Bf9f510d004BdB90d53Bed24642,
    0x2669Ac0238c3f0Fd48ac5D5381A95B8689879843,
    0xe94bE7b9400FFD079f1CD1EcF64c41566bc09E96,
    0xc9e8962B1f2c7C196e8dE40923fd83dBD7d9CF53,
    0x90270c8DCEffD69a98DEB0A8C73c5D3e1a1623ca,
    0x205BCC1d3ad128a2B9A6147E4c0604d0ed38a5D2
  ];

  uint[] private _shares = [
    15.00 * 1e3,
    13.50 * 1e3,
    13.50 * 1e3,
     2.50 * 1e3,
     2.50 * 1e3,

     5.00 * 1e3,
     3.00 * 1e3,
     5.00 * 1e3,
     2.50 * 1e3,
     2.50 * 1e3,
     0.50 * 1e3,
     0.50 * 1e3,
     0.50 * 1e3,
    33.50 * 1e3
  ];

  constructor()
    ERC721B("Elon Effect", "EE", 0)
    PaymentSplitterMod( _accounts, _shares ){
    setSignedConfig( 'Elon in full effect', 0xFe8148c69Ce6c25dC16659675B152ed7413D5465 );
  }

  //safety first
  fallback() external payable {}

  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "ElonEffect: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  //payable
  function claim() external {
    require( isClaimActive, "ElonEffect: claims are not active" );

    uint supply = totalSupply();
    uint quantity = claims[ msg.sender ];
    require( supply + quantity <= MAX_SUPPLY, "ElonEffect: claim exceeds supply" );

    claims[ msg.sender ] = 0;
    owners[msg.sender].balance += uint16(quantity);
    for( uint i; i < quantity; ++i ){
      _mint( msg.sender, supply++ );
    }
  }

  function mint( uint quantity, bytes calldata signature ) external payable {
    require( 0 < quantity && quantity <= MAX_ORDER,  "ElonEffect: order too big"             );
    require( msg.value >= PRICE * quantity,          "ElonEffect: ether sent is not correct" );

    if( isMainsaleActive ){
      //no-op
    }
    else if( isPresaleActive ){
      require( isAuthorizedSigner( quantity.toString(), signature ),  "ElonEffect: Account not authorized" );
    }
    else{
      revert( "ElonEffect: sale is not active" );
    }

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "ElonEffect: mint/order exceeds supply" );

    owners[msg.sender].balance += uint16(quantity);
    owners[msg.sender].purchased += uint16(quantity);
    for( uint i; i < quantity; ++i ){
      _mint( msg.sender, supply++ );
    }
  }


  //onlyDelegates
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "ElonEffect: must provide equal quantities and recipients" );

    unchecked{
      uint totalQuantity;
      for(uint i; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
      uint supply = totalSupply();
      require( supply + totalQuantity <= MAX_SUPPLY, "ElonEffect: mint/order exceeds supply" );

      for(uint i; i < recipient.length; ++i){
        if( quantity[i] > 0 ){
          owners[recipient[i]].balance += uint16(quantity[i]);
          for( uint j; j < quantity[i]; ++j ){
            _mint( recipient[i], supply++ );
          }
        }
      }
    }
  }

  function setActive(bool isClaimActive_, bool isPresaleActive_, bool isMainsaleActive_) external onlyDelegates{
    isClaimActive = isClaimActive_;
    isPresaleActive = isPresaleActive_;
    isMainsaleActive = isMainsaleActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setClaims(address[] calldata accounts, uint[] calldata quantities) external onlyDelegates{
    require( accounts.length == quantities.length, "ElonEffect: must have equal accounts and quantities" );
    for(uint i; i < accounts.length; ++i ){
      claims[ accounts[i] ] = quantities[i];
    }
  }

  function setConfig(uint maxOrder, uint maxSupply, uint maxMint, uint price) external onlyDelegates{
    require( maxSupply >= totalSupply(), "ElonEffect: specified supply is lower than current balance" );
    MAX_ORDER  = maxOrder;
    MAX_SUPPLY = maxSupply;
    MAX_MINT   = maxMint;
    PRICE      = price;
  }


  //private
  function _mint( address to, uint tokenId ) internal override {
    tokens.push( Token( to ) );
    emit Transfer( address(0), to, tokenId );
  }


  function addPayee(address account, uint256 shares_) external onlyOwner {
    _addPayee( account, shares_ );
  }

  function resetCounters() external onlyOwner {
    _resetCounters();
  }

  function setPayee( uint index, address account, uint newShares ) external onlyOwner {
    _setPayee(index, account, newShares);
  }
}
