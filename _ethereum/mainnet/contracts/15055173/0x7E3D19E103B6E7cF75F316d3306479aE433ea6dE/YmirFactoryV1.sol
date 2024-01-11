// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./YmirERC721.sol";
import "./Ownable.sol";

contract YmirFactoryV1 is Ownable {
  uint256 internal totalSupply;
  uint256 public fee = 1 ether;

  event MintContract(
    address contractAddress,
    address creator,
    string name,
    string symbol
  );

  event Received(address contractAddress, address sender, uint256 amount);

  event FeeChanged(uint256 newFee);

  event Withdraw(address sender, uint256 amount);

  function mintContract(string memory _name, string memory _symbol)
    public
    payable
    returns (address)
  {
    require(msg.value >= fee, "fee is required");
    YmirERC721 newContract = new YmirERC721(_name, _symbol, msg.sender);
    emit MintContract(address(newContract), msg.sender, _name, _symbol);
    totalSupply++;
    return address(newContract);
  }

  function setFee(uint256 _fee) public onlyOwner {
    fee = _fee;
    emit FeeChanged(fee);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No ether to withdraw");
    payable(owner()).transfer(balance);
    emit Withdraw(address(this), balance);
  }

  function getTotalSupply() public view returns (uint256) {
    return totalSupply;
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  receive() external payable {
    emit Received(address(this), msg.sender, msg.value);
  }

  fallback() external payable {}
}
