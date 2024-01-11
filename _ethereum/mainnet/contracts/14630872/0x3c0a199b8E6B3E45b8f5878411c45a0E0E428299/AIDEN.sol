// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/****************************************
 * @author: @hammm.eth                  *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./Delegated.sol";
import "./ERC721Batch.sol";
import "./PaymentSplitterMod.sol";
import "./Strings.sol";

interface IApertusSphera {
	function balanceOf(address account, uint256 id) external view returns (uint256);
    function burn( address account, uint id, uint quantity ) external payable;
    function exists( uint id ) external view returns (bool);
}

contract AIDEN is Delegated, ERC721Batch, PaymentSplitterMod {
  using Strings for uint;

  uint public MAX_SUPPLY = 3333;
  bool public PAUSED = false;

  IApertusSphera public ApertusSpheraProxy = IApertusSphera(0x683776E1768FdDBF1Ce43E505703F2f4df64FD12);

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  constructor()
    Delegated()
    ERC721B("A.I.D.E.N.", "AIDEN", 0){

    _addPayee( 0x608D6C1f1bD9a99565a7C2ED41B5E8e1A2599284, 90 );
    _addPayee( 0xC4719EE5b5A75cFDB3E770Ae42C6C29Fa9144dD6,  5 );
    _addPayee( 0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A,  5 );
  }


  //external
  function claim( uint quantity ) external {
    require( !PAUSED , "Claim is paused" );
    require( quantity > 0, "Quantity must be greater than 0" );
    require( totalSupply() + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    ApertusSpheraProxy.burn( msg.sender, 0, quantity );

    owners[ msg.sender ].balance += uint16(quantity);
    owners[ msg.sender ].purchased += uint16(quantity);
    for( uint i; i < quantity; ++i ) {
      _mint( msg.sender, _next() );
    }
  }

  function claimAll() external {
    require( !PAUSED , "Claim is paused." );

    uint quantity = ApertusSpheraProxy.balanceOf( msg.sender, 0 );
    require( quantity > 0, "Must own an Apertus Sphera to claim" );
    require( totalSupply() + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    ApertusSpheraProxy.burn( msg.sender, 0, quantity );

    owners[ msg.sender ].balance += uint16(quantity);
    owners[ msg.sender ].purchased += uint16(quantity);
    for( uint i; i < quantity; ++i ) {
      _mint( msg.sender, _next() );
    }
  }

  function tokenURI(uint tokenId) external view override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //onlyDelegates
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    unchecked{
      uint totalQuantity;
      for(uint i; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
      uint supply = totalSupply();
      require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );

      for(uint i; i < recipient.length; ++i){
        if( quantity[i] > 0 ){
          owners[recipient[i]].balance += uint16(quantity[i]);
          for( uint j; j < quantity[i]; ++j ){
            _mint( recipient[i], _next() );
          }
        }
      }
    }
  }

  function setURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function togglePause() external onlyDelegates {
    PAUSED = !PAUSED;
  }

  function setMaxSupply( uint _newMaxSupply ) external onlyDelegates { 
    require( totalSupply() <= _newMaxSupply, "New supply must be greater than current supply");
    MAX_SUPPLY = _newMaxSupply;
  }

  function setApertusSpheraContract(address _apertusSphera) external onlyDelegates {
    ApertusSpheraProxy = IApertusSphera(_apertusSphera);
  }

  function _mint(address to, uint tokenId) internal override {
    tokens.push(Token(to));
    emit Transfer(address(0), to, tokenId);
  }
}