// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BridgeBase.sol";

contract BridgeEth is BridgeBase {
  constructor(address token) BridgeBase(token) {}

  function burn(address to, uint amount, uint nonce, bytes calldata signature) external virtual override {
    _beforeTokenTransfer();
    bytes32 message = prefixed(keccak256(abi.encodePacked(
      msg.sender,
      to,
      'ETH-BURN',
      amount,
      nonce
    )));  
    require(recoverSigner(message, signature) == admin, 'wrong signature');
    require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
    processedNonces[msg.sender][nonce] = true;
    token.bridgeBurn(msg.sender, amount);
    emit Transfer(
      msg.sender,
      to,
      'ETH-BURN',
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Burn
    );
  }

  function mint(
    address from, 
    address to,
    uint amount, 
    uint nonce,
    bytes calldata signature
  ) external virtual override {
    _beforeTokenTransfer();
    bytes32 message = prefixed(keccak256(abi.encodePacked(
      from, 
      to,
      'ETH-MINT',
      amount,
      nonce
    )));
    require(recoverSigner(message, signature) == admin, 'wrong signature');
    require(processedNonces[from][nonce] == false, 'transfer already processed');
    processedNonces[from][nonce] = true;
    token.bridgeMint(to, amount);
    emit Transfer(
      from,
      to,
      'ETH-MINT',
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Mint
    );
  }

  function _beforeTokenTransfer() internal override { 
      require(!paused(), "ERC20Pausable: token transfer while contract paused");
  }
}
