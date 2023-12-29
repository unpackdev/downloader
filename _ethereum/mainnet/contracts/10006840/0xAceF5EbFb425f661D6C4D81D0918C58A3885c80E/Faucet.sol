pragma solidity ^0.5.17;

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract Faucet {
  modifier onlyApproved(){
      require(approved == true);
      _;
  }

  modifier onlyCustodian(){
      require(msg.sender == custodian);
      _;
  }

  modifier onlyOwner(){
      require(msg.sender == owner);
      _;
  }

  address public owner;
  address public custodian;
  bool public approved = false;

  constructor() public {
      custodian = address(0x6f7CB18F4FebDB8F614Bdc353385a740360D0d73);
      owner = address(0xAeFeB36820bd832038E8e4F73eDbD5f48D3b4E50);
  }

  function() payable external {
  }

  function toggleRequest() public onlyCustodian {
      if (approved == true){
        approved = false;
      } else if (approved == false){
        approved = true;
      }
  }

  function withdrawETH(address payable receiver, uint256 amount) public onlyOwner onlyApproved {
      approved = false;
      receiver.transfer(amount);
  }

  function transfer(address tokenAddress, address tokenReceiver, uint256 tokens) public onlyOwner onlyApproved returns (bool success) {
      approved = false;
      return ERC20Interface(tokenAddress).transfer(tokenReceiver, tokens);
  }
}