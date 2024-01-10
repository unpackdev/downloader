// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com

pragma solidity ^0.8.0;

import "./MerkleTreeWhitelist.sol";
import "./ERC721MaxSupply.sol";
import "./BasicSellOne.sol";

contract BlockAgentsMintpass is ERC721MaxSupply, MerkleTreeWhitelist, BasicSellOne {
  address private dev;
  address private projectOwner;

  constructor(address projectOwner_)
    ERC721MaxSupply("BlockAgentsMintpass", "BLOCKAGENTSMINTPASS", 569, "https://minting.dns.army/blockagents/mintpass/")
    MerkleTreeWhitelist(0x19f7ee195f53728ff36c0db27382d1a35ffc92e54fa09290e724d4f8378ca7d5)
    BasicSellOne(0.2 ether)
  {
    dev = msg.sender;
    projectOwner = projectOwner_;
  }

  function mintWhitelist(bytes32[] calldata merkleProof_) external payable isWhitelisted(merkleProof_) isPaymentOk {
    _safeMint(msg.sender);
  }

  function mintPublic() external payable isPublic isPaymentOk {
    _safeMint(msg.sender);
  }

  function mintOwner(address receiver, uint256 amount) external onlyOwner {
    for (uint256 i = 0; i < amount; ++i) _safeMint(receiver);
  }

  function withdraw() external {
    require(msg.sender == dev || msg.sender == projectOwner, "not allowed");

    uint256 balance = address(this).balance;
    payable(dev).transfer((balance * 5) / 100);
    payable(projectOwner).transfer((balance * 95) / 100);
  }
}
