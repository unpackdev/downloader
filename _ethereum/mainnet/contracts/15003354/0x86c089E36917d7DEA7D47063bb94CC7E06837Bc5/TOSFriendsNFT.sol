// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: tos_nft                 *
 * @team:   TheOtherSide                *
 ****************************************
 *   TOS-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./Delegated.sol";
import "./ERC721EnumerableT.sol";
import "./Strings.sol";
import "./SafeMath.sol";

interface IERC20Proxy{
  function burnFromAccount( address account, uint leaves ) external payable;
  function mintToAccount( address[] calldata accounts, uint[] calldata leaves ) external payable;
}

interface IERC1155Proxy{
  function burnFrom( address account, uint[] calldata ids, uint[] calldata quantities ) external payable;
}

contract TOSFriendsNFT is ERC721EnumerableT, Delegated {
  using Strings for uint;
  using SafeMath for uint256;

  struct Moon {
    address owner;
  }

  bool public revealed = true;
  string public notRevealedUri = "";

  uint public MAX_SUPPLY   = 11;
  uint public PRICE        = 0.15 ether;
  uint public MAX_QTY = 1;

  Moon[] public moons;

  bool public isMintActive = true;

  mapping(address => uint) private _balances;
  string private _tokenURIPrefix = "ipfs://QmQ3NX6QTHkqnbKPPCEXAk9GpGuokQtniupcBskwa3HzoX/";
  string private _tokenURISuffix =  ".json";

  constructor()
  ERC721T("TOS Frens v1", "TOSFRENS-1"){
  }

  //external
  fallback() external payable {}
  receive() external payable {}


  function balanceOf(address account) public view override returns (uint) {
    require(account != address(0), "MOON: balance query for the zero address");
    return _balances[account];
  }

  function isOwnerOf( address account, uint[] calldata tokenIds ) external view override returns( bool ){
    for(uint i; i < tokenIds.length; ++i ){
      if( moons[ tokenIds[i] ].owner != account )
        return false;
    }

    return true;
  }

  function ownerOf( uint tokenId ) public override view returns( address owner_ ){
    address owner = moons[tokenId].owner;
    require(owner != address(0), "MOON: query for nonexistent token");
    return owner;
  }

  function tokenByIndex(uint index) external view override returns (uint) {
    require(index < totalSupply(), "MOON: global index out of bounds");
    return index;
  }

  function tokenOfOwnerByIndex(address owner, uint index) public view override returns (uint tokenId) {
    uint count;
    for( uint i; i < moons.length; ++i ){
      if( owner == moons[i].owner ){
        if( count == index )
          return i;
        else
          ++count;
      }
    }
    revert("ERC721Enumerable: owner index out of bounds");
  }

  function tokenURI(uint tokenId) external view override returns (string memory) {
    require(_exists(tokenId), "MOON: URI query for nonexistent token");

    if(revealed == false) {
      return notRevealedUri;
    }
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  function totalSupply() public view override returns( uint totalSupply_ ){
    return moons.length;
  }

  function walletOfOwner( address account ) external view override returns( uint[] memory ){
    uint quantity = balanceOf( account );
    uint[] memory wallet = new uint[]( quantity );
    for( uint i; i < quantity; ++i ){
      wallet[i] = tokenOfOwnerByIndex( account, i );
    }
    return wallet;
  }

  //only delegates
  function setRevealState(bool reveal_) external onlyDelegates {
    revealed = reveal_;
  }

  //payable
  function mint( uint quantity ) external payable {
    require(isMintActive == true,"MOON: Minting needs to be enabled.");
    require(quantity <= MAX_QTY, "MOON:Quantity must be less than or equal to MAX QTY");
    require( msg.value >= PRICE * quantity, "MOON: Ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "MOON: Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++);
    }
  }

  function getBalanceOfContract() public view returns (uint256) {
    return address(this).balance;
  }

  function getContractAddress() public view returns (address) {
    return address(this);
  }

  function withdraw(uint256 amount_) public onlyOwner {
    require(address(this).balance >= amount_, "Address: insufficient balance");

    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: amount_}("");
    require(os);
    // =============================================================================
  }


  //onlyDelegates
  function teamMint(uint[] calldata quantity, address[] calldata recipient) external onlyDelegates{
    require(quantity.length == recipient.length, "MOON: Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= MAX_SUPPLY, "MOON: Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        uint tokenId = supply++;
        _mint( recipient[i], tokenId);
      }
    }
  }

  function setMintingActive(bool mintActive_) external onlyDelegates {
    isMintActive = mintActive_;
  }

  function setBaseURI(string calldata prefix, string calldata suffix) external onlyDelegates{
    _tokenURIPrefix = prefix;
    _tokenURISuffix = suffix;
  }

  function increaseMaxSupply(uint maxSupply) external onlyDelegates{
    require(MAX_SUPPLY != maxSupply, "MOON: New value matches old" );
    require(maxSupply >= totalSupply(), "MOON: Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }

  function setPrice(uint price) external onlyDelegates{
    require( PRICE != price, "MOON: New value matches old" );
    PRICE = price;
  }

  //internal
  function _beforeTokenTransfer(address from, address to) internal {
    if( from != address(0) )
      --_balances[ from ];

    if( to != address(0) )
      ++_balances[ to ];
  }

  function _exists(uint tokenId) internal view override returns (bool) {
    return tokenId < moons.length && moons[tokenId].owner != address(0);
  }

  function _mint(address to, uint tokenId) internal {
    _beforeTokenTransfer(address(0), to);
    moons.push(Moon(to));
    emit Transfer(address(0), to, tokenId);
  }

  function _transfer(address from, address to, uint tokenId) internal override {
    require(moons[tokenId].owner == from, "MOON: transfer of token that is not owned");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    _beforeTokenTransfer(from, to);

    moons[tokenId].owner = to;
    emit Transfer(from, to, tokenId);
  }

}