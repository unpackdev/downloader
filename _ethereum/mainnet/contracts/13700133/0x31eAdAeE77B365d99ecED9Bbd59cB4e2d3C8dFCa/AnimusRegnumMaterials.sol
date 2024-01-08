
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.4;

/****************************************
 * @author: Squeebo                     *
 * @team:   Golden X                    *
 ****************************************/

import "./Delegated.sol";
import "./MaticERC1155.sol";
import "./PaymentSplitter.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract AnimusRegnumMaterials is Delegated, MaticERC1155, PaymentSplitter{
  struct Token{
    uint burnPrice;
    uint mintPrice;
    uint balance;
    uint maxWallet;
    uint supply;

    bool isBurnActive;
    bool isMintActive;

    string name;
    string uri;
  }

  Token[] public tokens;

  /** BEGIN: OS required **/
  string public name = "Animus Regnum: Materials";
  string public symbol = "AR:M";
  mapping (uint => address) public creators;

  //address private proxyRegistryAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; //rinkeby
  address private proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; //mainnet
  //address private proxyRegistryAddress = 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c; //mumbai
  //address private proxyRegistryAddress = 0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101; //polygon
  /** END: OS required **/
  

  address[] private payees = [
    0x608D6C1f1bD9a99565a7C2ED41B5E8e1A2599284,
    0x42e98CdB46444c96B8fDc93Da2fcfd9a77FA9575,
    0xBd855c639584686315cb5bdfC7190057BC2a2A08,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];

  uint[] private splits = [
    85,
     5,
     5,
     5
  ];

  constructor()
    Delegated()
    MaticERC1155(name, "")
    PaymentSplitter( payees, splits ){
  }

  function exists(uint id) external view returns (bool) {
    return id < tokens.length;
  }


  /** BEGIN: OS required **/
  //external
  function create( address initialOwner, uint supply, string calldata uri_, bytes calldata data_ )
    external onlyDelegates returns (uint) {
    uint id = tokens.length;
    setToken( id, "", uri_, supply, supply, false, 0, false, 0 );
    return id;
  }

  function tokenSupply( uint id ) external view returns( uint ){
    require(id < tokens.length, "Specified token (id) does not exist" );
    return tokens[id].supply;
  }

  function totalSupply(uint id) external view returns (uint) {
    require(id < tokens.length, "Specified token (id) does not exist" );
    return tokens[id].supply;
  }

  //public
  //@see proxyRegistryAddress
  function isApprovedForAll( address _owner, address _operator ) public virtual override view returns (bool isOperator) {
    // if OpenSea's ERC721 Proxy Address is detected, auto-return true
    if (_operator == proxyRegistryAddress) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  function uri(uint id) public override view returns (string memory){
    require(id < tokens.length, "Specified token (id) does not exist" );
    return tokens[id].uri;
  }
  /** END: OS required **/


  //external
  fallback() external payable {}

  function mint( uint id, uint quantity ) external payable{
    require( id < tokens.length, "Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.isMintActive,                       "Sale is not active"        );
    require( token.balance + quantity <= token.supply, "Not enough supply"         );
    require( msg.value >= token.mintPrice * quantity,  "Ether sent is not correct" );

    _mint( _msgSender(), id, quantity, "" );
    token.balance += quantity;
  }

  function mintBatch( uint[] calldata ids, uint[] calldata quantities, bytes calldata data) external payable{
    uint totalRequired;
    for(uint i; i < ids.length; ++i){
      require( ids[i] < tokens.length, "Specified token (id) does not exist" );

      uint quantity = quantities[i];
      Token storage token = tokens[ids[i]];
      require( token.isMintActive,                       "Sale is not active"        );
      require( token.balance + quantity <= token.supply, "Not enough supply"         );
      require( balanceOf( _msgSender(), ids[i] ) + quantity < token.maxWallet, "Don't be greedy" );
      require( msg.value >= token.mintPrice * quantity,  "Ether sent is not correct" );
      totalRequired += ( token.mintPrice * quantity );      
      token.balance += quantity;
    }

    require( msg.value >= totalRequired,  "Ether sent is not correct" );
    _mintBatch( _msgSender(), ids, quantities, data );
  }


  //delegated
  function burn( address account, uint id, uint quantity ) external payable onlyDelegates{
    require( id < tokens.length, "Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance >= quantity, "Not enough supply" );

    token.balance -= quantity;
    token.supply -= quantity;
    _burn( account, id, quantity );
  }

  function burnBatch( address account, uint[] calldata ids, uint[] calldata quantities) external payable onlyDelegates{
    for(uint i; i < ids.length; ++i){
      require( ids[i] < tokens.length, "Specified token (id) does not exist" );

      uint quantity = quantities[i];
      Token storage token = tokens[ids[i]];
      require( token.balance >= quantity, "Not enough supply" );

      token.balance -= quantity;
      token.supply -= quantity;
    }

    _burnBatch( account, ids, quantities );
  }

  function mintTo( address[] calldata accounts, uint[] calldata ids, uint[] calldata quantities ) external payable onlyDelegates {
    require( accounts.length == ids.length,   "Must provide equal accounts and ids" );
    require( ids.length == quantities.length, "Must provide equal ids and quantities");

    for(uint i; i < ids.length; ++i ){
      require( ids[i] < tokens.length, "Specified token (id) does not exist" );

      Token storage token = tokens[ids[i]];
      require( token.balance + quantities[i] <= token.supply, "Not enough supply" );

      token.balance += quantities[i];
      _mint( accounts[i], ids[i], quantities[i], "" );
    }
  }

  function mintBatchTo( address account, uint[] calldata ids, uint[] calldata quantities, bytes calldata data) external payable onlyDelegates{
    for(uint i; i < ids.length; ++i){
      require( ids[i] < tokens.length, "Specified token (id) does not exist" );

      uint quantity = quantities[i];
      Token storage token = tokens[ids[i]];
      require( token.balance + quantity <= token.supply, "Not enough supply"         );
      token.balance += quantity;
    }

    _mintBatch( account, ids, quantities, data );
  }


  //delegated
  function setToken(uint id, string memory name_, string calldata uri_,
    uint maxWallet, uint supply,
    bool isBurnActive, uint burnPrice,
    bool isMintActive, uint mintPrice ) public onlyDelegates{
    require( id < tokens.length || id == tokens.length, "Invalid token id" );

    if( id == tokens.length ){
      creators[ id ] = _msgSender();
      tokens.push();
    }


    Token storage token = tokens[id];
    token.name         = name_;
    token.uri          = uri_;

    setActive(id, isBurnActive, isMintActive);
    setPrice(id, burnPrice, mintPrice);
    setSupply(id, maxWallet, supply);

    if (bytes(uri_).length > 0)
      emit URI( uri_, id );
  }

  function setActive(uint id, bool isBurnActive, bool isMintActive) public onlyDelegates{
    require( id < tokens.length, "Specified token (id) does not exist" );
    require( tokens[id].isBurnActive != isBurnActive || tokens[id].isMintActive != isMintActive, "New value matches old" );
    tokens[id].isBurnActive = isBurnActive;
    tokens[id].isMintActive = isMintActive;
  }

  function setPrice(uint id, uint burnPrice, uint mintPrice) public onlyDelegates{
    require( id < tokens.length, "Specified token (id) does not exist" );
    require( tokens[id].burnPrice != burnPrice || tokens[id].mintPrice != mintPrice, "New value matches old" );
    tokens[id].burnPrice = burnPrice;
    tokens[id].mintPrice = mintPrice;
  }

  function setSupply(uint id, uint maxWallet, uint supply) public onlyDelegates{
    require( id < tokens.length, "Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.maxWallet != maxWallet || token.supply != supply,  "New value matches old" );
    require( token.balance <= supply, "Specified supply is lower than current balance" );
    token.maxWallet = maxWallet;
    token.supply = supply;
  }

  function setURI(uint id, string calldata uri_) external onlyDelegates{
    require( id < tokens.length, "Specified token (id) does not exist" );
    tokens[id].uri = uri_;
    emit URI( uri_, id );
  }


  //internal
  function _msgSender() internal virtual override(Context,MaticERC1155) view returns (address sender){
    return ContextMixin.msgSender();
  }
}
