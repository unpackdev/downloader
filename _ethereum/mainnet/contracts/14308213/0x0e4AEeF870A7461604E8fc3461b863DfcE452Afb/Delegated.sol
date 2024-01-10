// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
contract Delegated is Ownable{
  mapping(address => bool) internal _delegates;
  constructor(){
    _delegates[owner()] = true;
  }
  modifier onlyDelegates {
    require(_delegates[msg.sender], "******** YOU ARE NOT A DELEGATE ! ************" );
    _;
  }
  //onlyOwner
  function isDelegate( address addr ) external view onlyOwner returns ( bool ){
    return _delegates[addr];
  }
  function setDelegate( address addr, bool isDelegate_ ) external onlyOwner{
    _delegates[addr] = isDelegate_;
  }
}