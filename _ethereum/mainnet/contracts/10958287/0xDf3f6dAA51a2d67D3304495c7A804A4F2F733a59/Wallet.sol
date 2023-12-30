pragma solidity ^0.6.0;

interface IERC20 {
  function transfer(address recipient, uint amount) external returns (bool);
}

contract Wallet {

  address public constant owner = 0x38bce4B45F3d0D138927Ab221560dAc926999ba6;

  function transfer(IERC20 _token, address _to, uint _amount) external {
    require(owner == msg.sender, "Wallet: not owner");
    _token.transfer(_to, _amount);
  }
}