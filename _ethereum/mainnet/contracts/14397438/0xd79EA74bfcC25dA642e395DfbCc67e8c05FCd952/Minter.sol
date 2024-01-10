// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./StrangeOdyssey.sol";

contract Minter is Ownable {
  StrangeOdyssey private token;
  address private contractAddress;

  uint256 public BASE_PRICE = 0.0 ether;
  uint256 public MAX_SUPPLY = 1;

  event ResultsFromCall(bool success, bytes data);

  constructor() {}

  receive() external payable {}

  fallback() external payable {}

  /**
    ***************************
    Public
    ***************************
    */
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function mint(address to) public payable {
    require(token.totalSupply() < MAX_SUPPLY, 'No more left to mint');
    require(msg.value >= BASE_PRICE, 'Need to send more ether');
    token.safeMint(to);
  }

  /**
    ***************************
    Only Owner
    ***************************
    */

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, 'No ether left to withdraw');

    (bool success, bytes memory data) = (msg.sender).call{value: balance}('');
    require(success, 'Withdrawal failed');
    emit ResultsFromCall(success, data);
  }

  /**
    ***************************
    Customization for the contract
    ***************************
    */

  function setContractAddress(address payable _address) external onlyOwner {
    contractAddress = _address;
    token = StrangeOdyssey(_address);
  }

  function setBasePrice(uint256 _basePrice) public onlyOwner {
    BASE_PRICE = _basePrice;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    MAX_SUPPLY = _maxSupply;
  }
}
