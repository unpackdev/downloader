pragma solidity 0.5.17;


contract Ownable
{
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  modifier onlyOwner()
  {
    require(isOwner(), "!owner");
    _;
  }

  constructor () internal
  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner() public view returns (address)
  {
    return _owner;
  }

  function isOwner() public view returns (bool)
  {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner
  {
    emit OwnershipTransferred(_owner, address(0));

    _owner = address(0);
  }

  function transferOwnership(address _newOwner) public onlyOwner
  {
    require(_newOwner != address(0), "0 addy");

    emit OwnershipTransferred(_owner, _newOwner);

    _owner = _newOwner;
  }
}
