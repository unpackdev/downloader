
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   Asteria                     *
 ****************************************/


//IERC165.sol
import "./Delegated.sol";
import "./ERC1155.sol";

contract StarShopBase is Delegated, ERC1155 {
  struct Token{
    uint burnPrice;
    uint mintPrice;
    uint balance;
    uint supply;

    bool burnStar;
    bool isBurnActive;
    bool isMintActive;

    string name;
    string uri;
  }

  Token[] public tokens;

  address proxyRegistryAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317;
  //rinkeby: 0xF57B2c51dED3A29e6891aba85459d600256Cf317
  //mainnet: 0xa5409ec958C83C3f309868babACA7c86DCB077c1
  //mumbai:  0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
  //polygon: 0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101

  constructor()
    Delegated()
    ERC1155(""){
  }


  //safety first
  fallback() external payable {}

  receive() external payable {}

  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }


  //public
  function exists(uint id) public view returns (bool) {
    return id < tokens.length;
  }

  function tokenSupply( uint id ) external view returns( uint ){
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    return tokens[id].supply;
  }

  function totalSupply( uint id ) external view returns( uint ){
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    return tokens[id].supply;
  }

  function uri( uint id ) public view override returns( string memory ){
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    return tokens[id].uri;
  }


  //delegated
  function burnFrom( address account, uint[] calldata ids, uint[] calldata quantities ) external payable onlyDelegates {
    require( ids.length == quantities.length, "ERC1155: Must provide equal ids and quantities");

    for(uint i; i < ids.length; ++i ){
      _burn( account, ids[i], quantities[i] );
    }
  }

  function mintTo( address[] calldata accounts, uint[] calldata ids, uint[] calldata quantities ) external payable onlyDelegates {
    require( accounts.length == ids.length,   "ERC1155: Must provide equal accounts and ids" );
    require( ids.length == quantities.length, "ERC1155: Must provide equal ids and quantities");
    for(uint i; i < ids.length; ++i ){
      _mint( accounts[i], ids[i], quantities[i], "" );
    }
  }

  function setToken(uint id, string memory name_, string memory uri_, uint supply,
    bool isBurnActive, uint burnPrice,
    bool isMintActive, uint mintPrice, bool burnStar ) public onlyDelegates{
    require( id < tokens.length || id == tokens.length, "ERC1155: Invalid token id" );
    if( id == tokens.length ){
      tokens.push();
    }
    else{
      require( tokens[id].balance <= supply, "ERC1155: Specified supply is lower than current balance" );
    }


    Token storage token = tokens[id];
    token.name         = name_;
    token.uri          = uri_;
    token.isBurnActive = isBurnActive;
    token.isMintActive = isMintActive;
    token.burnPrice    = burnPrice;
    token.mintPrice    = mintPrice;
    token.supply       = supply;
    token.burnStar     = burnStar;

    if( bytes(uri_).length > 0 )
      emit URI( uri_, id );
  }

  function setSupply(uint id, uint supply) public onlyDelegates {
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance <= supply, "ERC1155: Specified supply is lower than current balance" );
    token.supply = supply;
  }

  function setURI(uint id, string calldata uri_) external onlyDelegates{
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    tokens[id].uri = uri_;
    emit URI( uri_, id );
  }


  //internal
  function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override {
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance + amount <= token.supply, "ERC1155: Not enough supply" );

    token.balance += amount;
    super._mint( account, id, amount, data );
  }

  function _burn(address account, uint256 id, uint256 amount) internal virtual override {
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance >= amount, "ERC1155: Not enough supply" );

    tokens[id].balance -= amount;
    tokens[id].supply -= amount;
    super._burn( account, id, amount );
  }
}
