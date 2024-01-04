// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract PreSale is Ownable {
  using SafeMath for uint256;

  IERC20 public token;
  address public wallet;
  uint256 public rate;
  uint256 public weiRaised;

  constructor(uint256 _rate, address _wallet, address _token) {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = IERC20(_token);
  }

  function setRate(uint _rate) public onlyOwner {
      require(_rate > 0);

      rate = _rate;
  }

  receive() external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != address(0));
    require(msg.value != 0);

    uint256 tokens = msg.value.mul(rate);
    weiRaised = weiRaised.add(msg.value);

    token.transfer(_beneficiary, tokens);
    payable(wallet).transfer(msg.value);
  }
}