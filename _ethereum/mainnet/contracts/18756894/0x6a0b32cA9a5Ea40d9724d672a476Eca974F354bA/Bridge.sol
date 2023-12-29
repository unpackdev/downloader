// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./SafeERC20.sol";
import "./Ownable2Step.sol";
import "./IToken.sol";

contract Bridge is Ownable2Step {
  IToken public token;
  uint public nonce;
  bool public bridgeEnabled;

  mapping (address => mapping (uint => bool)) public sentProcessedNonce;
  mapping (address => mapping (uint => bool)) public receivedProcessedNonce;
  mapping (address => mapping (uint => bool)) public failedProcessedNonce;

  enum Step { Burn, Mint }

  event BridgeTransfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );

  event BridgeFailed(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce
  );

  constructor(address _token) {
    require(_token != address(0), "Bridge: Cannot set address(0)");
    token = IToken(_token);
    _transferOwnership(0x12926793D4c56AFEB8bC62Ede9842AE1F713a00b); // LP wallet and owner address
    bridgeEnabled = true;
  }

  modifier onlyBridgeEnabled() {
    require(bridgeEnabled, "Bridge: Bridge is not enabled!");
    _;
  }

  function sendTokens(address to, uint amount) external onlyBridgeEnabled() {
    require(!sentProcessedNonce[msg.sender][nonce], 'transfer already processed');
    sentProcessedNonce[msg.sender][nonce] = true;
    token.burn(msg.sender, amount);
    emit BridgeTransfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      Step.Burn
    );
    nonce++;
  }

  function receiveTokens(address from, address to, uint amount, uint otherChainNonce) external onlyOwner() {
    require(!receivedProcessedNonce[from][otherChainNonce], 'transfer already processed');
    receivedProcessedNonce[from][otherChainNonce] = true;
    token.mint(to, amount);
    emit BridgeTransfer(
      from,
      to,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.Mint
    );
  }

  function bridgeFailed(address from, address to, uint amount, uint sameChainNonce) external onlyOwner() {
    require(!failedProcessedNonce[from][sameChainNonce], 'bridge fail already processed');
    failedProcessedNonce[from][sameChainNonce] = true;
    token.mint(to, amount);
    emit BridgeFailed(
      from,
      to,
      amount,
      block.timestamp,
      sameChainNonce
    );
  }

  receive() external payable {}

  function withdrawETH() external onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function withdrawTokens(IERC20 tokenAddress, address walletAddress) external onlyOwner {
    require(
      walletAddress != address(0),
      "walletAddress can't be 0 address"
    );
    SafeERC20.safeTransfer(
      tokenAddress,
      walletAddress,
      tokenAddress.balanceOf(address(this))
    );
  }
}