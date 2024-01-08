pragma solidity ^0.6.2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./console.sol";

contract CodexICOTokenPurchase {
  using SafeMath for uint256;

  uint256 public rate;
  IERC20 public token;
  address public owner;

  constructor(IERC20 _token) public {
    // two billion
    rate = 2000000000;
    token = _token;
    owner = msg.sender;
  }

  // Send tokens back to the sender using predefined exchange rate
  receive() external payable {
    console.log("WEI received '%s' multiplying by '%s'", msg.value, rate);
    // msg.value is in WEI (10^18) so we don't need to multiple by decimals here, just rate
    uint256 tokens = msg.value.mul(rate);
    console.log("Transfer '%s' Codex to '%s'", tokens, msg.sender);
    token.transfer(msg.sender, tokens);
  }

  function withdraw() public {
    require(msg.sender == owner, "Address not allowed to call this function");
    msg.sender.transfer(address(this).balance);
  }
}
