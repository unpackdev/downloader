// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable 
{

  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor()
  {
    owner = msg.sender;
  }
  
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}