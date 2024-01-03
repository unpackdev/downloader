pragma solidity ^0.5.0;

import "./IOwnable.sol";


contract Ownable is
  IOwnable
{
  address public owner;
  address public operator;

  constructor ()
    public
  {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(
      msg.sender == owner,
      "ONLY_CONTRACT_OWNER"
    );
    _;
  }

  modifier onlyOperator() {
    require(
      msg.sender == operator,
      "ONLY_CONTRACT_OPERATOR"
    );
    _;
  }

  function transferOwnership(address newOwner)
    public
    onlyOwner
  {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

  function setOperator(address newOperator)
    public
    onlyOwner 
  {
    operator = newOperator;
  }
}
