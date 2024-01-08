// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./NamelessToken.sol";

contract NamelessMintingQueue is AccessControl {
  constructor( ) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  struct MintingInfo {
    uint256 tokenId;
    address tokenContract;
    address recipient;
  }

  mapping (address => MintingInfo[]) public queuedMintsByMinter;

  function addMintingInfo(address minter, address recipient, address tokenContract, uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
    queuedMintsByMinter[minter].push();
    uint newIndex = queuedMintsByMinter[minter].length -1;
    queuedMintsByMinter[minter][newIndex] = MintingInfo({
			tokenId: tokenId,
			tokenContract: tokenContract,
			recipient: recipient
		});
  }

  function processMintingQueue(uint maxTokens) public {
    MintingInfo[] storage queue = queuedMintsByMinter[msg.sender];
    require(queue.length > 0, 'Nothing to mint');

    uint numToMint = maxTokens < queue.length ? maxTokens : queue.length;
    for (uint idx = 0; idx < numToMint; idx++) {
      NamelessToken(queue[idx].tokenContract).mint(msg.sender, queue[idx].recipient, queue[idx].tokenId);
    }

    if (numToMint == queue.length) {
      delete queuedMintsByMinter[msg.sender];
    } else {
      uint remaining = queue.length - numToMint;
      for (uint idx = 0; idx < remaining; idx++) {
        queue[idx] = queue[numToMint + idx];
      }

      while (queue.length > remaining) {
        queue.pop();
      }
    }
  }
}
