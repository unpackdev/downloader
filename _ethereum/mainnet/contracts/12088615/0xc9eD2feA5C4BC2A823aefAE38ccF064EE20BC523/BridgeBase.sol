pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Itoken.sol";

contract BridgeBase is Ownable{
  IToken public token;
  uint public nonce;
  mapping(uint => bool) public processedNonces;

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint nonce,
    Step indexed step
  );

  constructor (address _token) Ownable() {
    token = IToken(_token);
  }

  function burn(uint amount) external {
    token.burn(msg.sender, amount);
    emit Transfer(
      msg.sender,
      address(0x0),
      amount,
      nonce,
      Step.Burn
    );
    nonce++;
  }

  function mint(address to, uint amount, uint otherChainNonce) external onlyOwner {
    require(processedNonces[otherChainNonce] == false, 'Transfer already processed');
    processedNonces[otherChainNonce] = true;
    token.mint(to, amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      otherChainNonce,
      Step.Mint
    );
  }

  function transferTokenOwnership(address newOwner) external onlyOwner {
    token.transferOwnership(newOwner);
  }

}
