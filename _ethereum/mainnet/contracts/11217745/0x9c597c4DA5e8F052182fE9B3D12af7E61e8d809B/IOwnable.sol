pragma solidity ^0.5.0;

contract IOwnable {
  function transferOwnership(address newOwner) public;

  function setOperator(address newOwner) public;
}
