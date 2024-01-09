
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/********************************
 * @author: squeebo_nft         *
 *   Blimpie provides low-gas   *
 *       mints + transfers      *
 ********************************/

import "./Strings.sol";
import "./Delegated.sol";
import "./PaymentSplitterMod.sol";
import "./T721Batch.sol";

interface IERC20Proxy{
  function burnFromAccount( address account, uint tw ) external;
  function mintToAccount( address account, uint tw ) external;
}

contract QwertyTurtles is Delegated, T721Batch, PaymentSplitterMod {
  using Strings for uint16;
  using Strings for uint256;

  uint public ETH_PRICE  = 0.025 ether;
  uint public MAX_ORDER  = 10;
  uint public MAX_SUPPLY = 5555;

  // //seconds
  bool public isActive;
  uint public qtyBurned;

  string private _tokenURIPrefix = "";
  string private _tokenURISuffix = "";

  address[] private addressList = [
    0x91f30728B869f2dDF36De0dB1c9C8f51d84606c2,
    0x46462Ee2B2e26561360ee7F629Da0Ff7E1F02B76,
    0xF403829905A2799076f741b2397d6c5f0c34D224
  ];
  uint[] private shareList = [
    90,
    5,
    5
  ];

  constructor()
    T721("QwertyTurtles", "QT")
    PaymentSplitterMod(addressList, shareList){
  }


  //view: external
  fallback() external payable {}

  function isFrozen( uint tokenId ) external view returns( bool isFrozen_ ){
    return _isStaked( tokenId );
  }


  //view: IERC721Enumerable
  function totalSupply() public view override returns( uint totalSupply_ ){
    return tokens.length - qtyBurned;
  }

  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "QuertyTurtles: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  function freeze( uint[] calldata tokenIds ) external {
    for(uint i; i < tokenIds.length; ++i ){
      require( _exists(tokenIds[i]), "QuertyTurtles: freeze for nonexistent token" );

      Token storage token = tokens[ tokenIds[i] ];
      require( token.owner == msg.sender, "QuertyTurtles: caller is not owner" );
      require( token.freezeDate < 2, string(abi.encodePacked("QuertyTurtles: token ", token.id.toString(), " is already frozen")));
      tokens[ tokenIds[ i ] ].freezeDate = uint32(block.timestamp);
    }
  }

  //payable
  function mint( uint quantity ) external payable {
    require( isActive,                          "QuertyTurtles: Sale is not active"        );
    require( quantity <= MAX_ORDER,             "QuertyTurtles: Order too big"             );
    require( msg.value >= ETH_PRICE * quantity, "QuertyTurtles: Ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "QuertyTurtles: Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender );
    }
  }

  //onlyDelegates
  function burnFrom( uint[] calldata tokenIds ) external{
    for(uint i; i < tokenIds.length; ++i){
      _burn( tokenIds[i] );
    }
  }

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
        _mint( recipient[i] );
      }
    }
  }

  function setActive(bool isActive_) external onlyDelegates{
    require( isActive != isActive_, "New value matches old" );
    isActive = isActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setMaxOrder(uint maxOrder, uint maxSupply) external onlyDelegates{
    require( maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
  }

  function setPrice( uint ethPrice ) external onlyDelegates{
    ETH_PRICE = ethPrice;
  }

  //private
  function _beforeTokenTransfer(address from, address to, uint tokenId) internal override{
    if( to == address(0) )
      ++qtyBurned;
  }

  function _burn(uint tokenId) private notStaked( tokenId ){
    address owner = ownerOf(tokenId);
    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);
    tokens[tokenId].owner = address(0);

    emit Transfer(owner, address(0), tokenId);    
  }

  function _isStaked( uint tokenId ) internal view override returns( bool isStaked_ ){
    return tokens[ tokenId ].freezeDate > 1;
  }

  function _mint( address to ) private {
    uint tokenId = tokens.length;
    _beforeTokenTransfer(address(0), to, tokenId);
    tokens.push(Token( to, uint16(tokenId), 0));
    emit Transfer(address(0), to, tokenId);
  }
}
