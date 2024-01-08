
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   The Tentaverse              *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************
░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░▓▒▓▓▓░▓▓▓▓▓▓▓░▓▓▓▓▓░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░▓▓▒▒▒░▓▓▓▓▓▓▓▓░▒▓▓▒▓▓░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░▒▓▓▓░▓▓▓▓▓▓▓▓▓▓▓▒░░▓▓▓░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░▒▓▓░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▒▓▓░░░░░░░░░░░░░░░░░
░░░░░▒▓▓▓▓░░░░░░░▓░░▓▓▒▓▓▓▓▒░▓▓▓░▓▓▓▓▒▓▓▒░▓░░░░░░░░░░░░░░░
░░░▓▓▓▒▒▒▓▓░░░░▒░▓▒░░▓░▒▓▓▓▒▒▓▓▓░▓▓▓▓░▓▓░▓▓░░░░░░░░░░░░░░░
░░▓▓░░░░░░░░░░░░▓▓▓▒▒▓▓░▒▓▓░▓▓▓▓▓░▓▒░▒▓░░▓▓▓▒░░░░░░░░░░░░░
░▓▓▒░░░░░░░░░░░▒▓▓▒▓▓▓▓▓▒▓░▓▓▓▓▓▓░▓▓▓▓▓▓▓▓▒▓░░░░░░░░░░░░░░
▓▓▓░░░░░░░░░░░░░▓▓▓▒▓▒▒▒▓▓▓░▒▓▓▒▒▓▓▓▓▒▒▓▓▒▓▓▓░░░░░░░▓▓▓▓░░
▓▓▓░░░░░░░░░░░░░▒▓▓▓▒▓▓▓▒▓▓▓▓░░▓▒▓▓▓▓▒▒▒▒▓▓░░░░░░░░▓▒░░░▓▒
░▓▓▓░░░░░░░░░░░░░░▓▒▓▓▓░░▓▓▒▓▓▓▓▓▓▒░▒▓▓▒▓░░░░░░░░░░░░░░░░▓
░▒▓▓▓▓░░░░░░░░░░░▓▓▓▓▓▓░▒▓▓▒▒▓▓▓▒▓▓░░▓▓▓▓▒░░░░░░░░░░░░░░▓▓
░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░░▒▒▓▓▓░
░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓░▓░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░
░░░░░░░░░░░░▒░▒░▒▓▓▓▓▓▓▓▒▓▒▓░▓▒▒▓░▓▒▓▓▓▓▓▓▒░▒░▒▒▓▒▓▒▓░░░░░
░░░░░░░░░▓▓▓▓▓▓▓▓▒░▓▓▓▓▓░▓░▓▓▓▓▓▓▒▓▓▓▓▓▓░▓▓▓▓▓▒▒▒▒░░░░░░░░
░░░░░░░▓▓▓░░░░░░░▒▓▓▓▓▓▒▓▓▒▓▓▓▓▓▓▓░▓▒▓▓▓▓░░░▒▒▒▒▓▓▓▓▓░░░░░
░░░░░░▒▓░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░▓▒▓▓░▓▓▓▓▒▓▒▒▓▓▓▓▓▓▓▒░░░░░▓▓░░░░
░░░░░░░▓▓░░░▓▓▓▓▓▓▓▒░░▓▓▓▓▒▓▓░░▓▓▓▒▓▒▓▓░░▒▓▓▓▓▓▓▓░▒░▒▓░░░░
░░░░░░░░▓▓▒▓▓▓░░▓▓░░░▓▓▒▒▓▓▒▓░░░▓▓▓▒▓▒▓▓▓░▒▓░░░░▓▓▒▓▓░░░░░
░░░░░░░░░░░░▓▓▓▓▓▒░░▓▓▓░▓▓▓▓▓▒░░▒▓▓▓▓▓░▒▓▓▒▓░░░░▓▓░░░░░░░░
░░░░░░░░░░░░░▒▓▒░░▓▓▓░░░░▓▓▓░░░░░░░▓▓▓▓░░▓▓▒▓▓▓▓▓▒░░░░░░░░
░░░░░░░░░░░░░░░░▓▓▓░░░░░░▓▓▓▒░░░░░░░▓▓▓▒░░▓▒░▒▒░░░░░░░░░░░
░░░░░░░░░░░░░░░▓▒░░░░▓▒▓▒▓▓▓░░░░░░░░▓▓▓░░░▓▓░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░▓▓▓▓░▓▓▒░░▓▓▓░▓▓▓▓▓▓▓▓▓░░▒▓▓▒░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░▓▓▓░░▓▓▓░░▓░░▒▓▓▓▓░░▓▒▒░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▒░░░▓▒░░░░░░░▒░░░░░░░░░░░░░░░░░░░
*/


import "./ERC721EnumerableLite.sol";
import "./Signed.sol";
import "./Strings.sol";

contract TheTentaverse is ERC721EnumerableLite, Signed {
  using Strings for uint;

  uint public MAX_ORDER  = 10;
  uint public MAX_SUPPLY = 6676;
  uint public MAX_WALLET = 10;
  uint public PRICE      = 0.08 ether;

  bool public isActive   = false;
  bool public isVerified = true;

  uint private _supply = 6276;
  string private _tokenURIPrefix = '';
  string private _tokenURISuffix = '';

  constructor()
    Delegated()
    ERC721B("The Tentaverse", "TT", 0){
  }

  //external
  fallback() external payable {}

  receive() external payable {}

  //public
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //external
  function mint( uint quantity, bytes calldata signature ) external payable {
    require( isActive,                      "Sale is not active"        );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    require( _balances[ msg.sender ] + quantity <= MAX_WALLET, string(abi.encodePacked( "Max ", MAX_WALLET.toString(), " per wallet")));
    require( msg.value >= PRICE * quantity, "Ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= _supply, "Mint/order exceeds supply" );
    if( isVerified )
      verifySignature( quantity.toString(), signature );

    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++ );
    }
  }

  //delegated
  function burnFrom(address account, uint[] calldata tokenIds) external payable onlyDelegates{
    for(uint i; i < tokenIds.length; ++i ){
      require( _owners[ tokenIds[i] ] == account, "Owner check failed" );
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
    require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    delete totalQuantity;

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i], supply++ );
      }
    }
  }

  function resurrect( address[] calldata recipients, uint[] calldata tokenIds ) external payable onlyDelegates{
    address zero = address(0);
    require(tokenIds.length == recipients.length,   "Must provide equal tokenIds and recipients" );
    for(uint i; i < tokenIds.length; ++i ){
      uint tokenId = tokenIds[i];
      require( !_exists( tokenId ), "Can't resurrect existing token" );

      --_burned;
      _owners[tokenId] = recipients[i];
      _approve(zero, tokenId);
      _beforeTokenTransfer(address(0), recipients[i], tokenId);
      emit Transfer(zero, recipients[i], tokenId);      
    }
  }

  function setActive(bool isActive_, bool isVerified_) external onlyDelegates{
    require( isActive != isActive_ || isVerified != isVerified_, "New value matches old" );
    isActive = isActive_;
    isVerified = isVerified_;
  }

  function setBaseURI(string calldata newPrefix, string calldata newSuffix) external onlyDelegates{
    _tokenURIPrefix = newPrefix;
    _tokenURISuffix = newSuffix;
  }

  function setMax(uint maxOrder, uint maxSupply, uint maxWallet, uint saleSupply) external onlyDelegates{
    require( MAX_ORDER != maxOrder ||
      MAX_SUPPLY != maxSupply ||
      MAX_WALLET != maxWallet, "New value matches old" );
    require(maxSupply >= totalSupply(), "Specified supply is lower than current balance" );

    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
    MAX_WALLET = maxWallet;
    _supply = saleSupply;
  }

  function setPrice(uint price ) external onlyDelegates{
    require( PRICE != price, "New value matches old" );
    PRICE = price;
  }

  function withdraw() external {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }

  function finalize() external onlyOwner {
    selfdestruct(payable(owner()));
  }


  //internal
  function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
    if( from != address(0) )
      --_balances[from];

    if( to != address(0) )
      ++_balances[to];
  }

  function _burn(uint tokenId) internal override {
    //failsafe
    address from = ownerOf(tokenId);
    _approve(owner(), tokenId);
    _beforeTokenTransfer( from, address(0), tokenId );

    ++_burned;
    _owners[tokenId] = address(0);
    emit Transfer(from, address(0), tokenId);
  }

  function _mint(address to, uint tokenId) internal override {
    _beforeTokenTransfer( address(0), to, tokenId );

    _owners.push(to);
    emit Transfer(address(0), to, tokenId);
  }
}
