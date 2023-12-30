pragma solidity ^0.6.0;

interface IERC20 {
  function transfer(address recipient, uint amount) external returns (bool);
}

contract Wallet {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function transfer(IERC20 _token, address _to, uint _amount) external {
    require(owner == msg.sender, "Wallet: not owner");
    _token.transfer(_to, _amount);
  }
}