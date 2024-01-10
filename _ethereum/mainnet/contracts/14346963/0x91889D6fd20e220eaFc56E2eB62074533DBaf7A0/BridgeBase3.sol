pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IToken.sol";

contract DoGiOhBridge is Ownable {
  IToken public token;
  uint256 public nonce = 0;
  mapping(uint256 => bool) public processedNonces;

  event BurnBridge(
    address from,
    address to,
    uint256 amount,
    uint256 date,
    uint256 nonce
  );

  event MintBridge(
    address from,
    address to,
    uint256 amount,
    uint256 date,
    uint256 nonce
  );

  constructor(address _token) {
    token = IToken(_token);
  }

  function burn(uint256 amount) external {
    token.burn(msg.sender, amount);
    emit BurnBridge(msg.sender, msg.sender, amount, block.timestamp, nonce);
    nonce++;
  }

  function mint(
    address from,
    address to,
    uint256 amount,
    uint256 _nonce
  ) external onlyOwner {
    require(processedNonces[_nonce] == false, "transfer already processed");
    processedNonces[_nonce] = true;
    token.mint(to, amount);
    emit MintBridge(from, to, amount, block.timestamp, _nonce);
  }
}
