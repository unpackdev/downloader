pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./SafeMath.sol";

contract A13Crowdsale {
  using SafeMath for uint256;

  address public owner;
  address public contractAddress;
  uint public rate;
  ERC20 public tokenToBuy;

  constructor (uint _rate) {
    require(_rate > 0);
    require(msg.sender != address(0));

    owner = msg.sender;
    rate = _rate;
    tokenToBuy = ERC20(address(0));
    contractAddress = address(this);
  }

  modifier onlyOwner {
    require(msg.sender == owner, "Only the owner can call this function.");
    _;
  }

  function setTokenToBuy (address _token) public onlyOwner {
    require(tokenToBuy == ERC20(address(0)), "ERC20 cannot be set more than once.");
    tokenToBuy = ERC20(_token);
  }

  function buyA13Token(uint256 numberOfTokens) public payable {
    require(tokenToBuy != ERC20(address(0)), "ERC20 token variable not set.");
    require(msg.value > 0, "Cannot send 0 Ether.");
    require(numberOfTokens > 0, "It would waste gas to try and buy 0 tokens.");
    require(numberOfTokens <= tokenToBuy.balanceOf(contractAddress), "Cannot buy more tokens than contract holds.");
    require(SafeMath.mul(rate, numberOfTokens) == msg.value, "Incorrect amount of Ether sent.");

    // Send A13 tokens to the caller of the function
    tokenToBuy.transfer(msg.sender, numberOfTokens);
  }

  function getBalanceOfToken() public view returns (uint) {
    return tokenToBuy.balanceOf(contractAddress);
  }

  function withdrawlERC20Tokens(address _token) onlyOwner public {
    ERC20(_token).transferFrom(contractAddress, owner, ERC20(_token).balanceOf(contractAddress));
  }

  function withdrawlA13Tokens(address _owner, uint _amount) onlyOwner public {
    require(tokenToBuy != ERC20(address(0)), "ERC20 token variable not set.");
    tokenToBuy.transferFrom(_owner, contractAddress, _amount);
  }

  function withdrawlEther() onlyOwner public {
    payable(msg.sender).transfer(contractAddress.balance);
  }

}
