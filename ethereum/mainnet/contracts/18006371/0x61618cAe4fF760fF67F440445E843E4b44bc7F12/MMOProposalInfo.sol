// SPDX-License-Identifier: MIT
// contract by steviep.eth


pragma solidity ^0.8.17;

interface IMMO {
  function ownerOf(uint256 tokenId) external view returns (address);
}

contract MMOProposalInfo {
  struct ProposalInfo {
    string proposalHref;
    string proposalStr;
  }

  mapping(uint256 => ProposalInfo) public tokenIdToInfo;

  IMMO public constant mmo = IMMO(0x41d3d86a84c8507A7Bc14F2491ec4d188FA944E7);

  function updateProposalInfo(
    uint256 tokenId,
    string calldata _proposalHref, 
    string calldata _proposalStr
  ) external {
    require(msg.sender == mmo.ownerOf(tokenId), 'Not owner of token');

    tokenIdToInfo[tokenId].proposalHref = _proposalHref;
    tokenIdToInfo[tokenId].proposalStr = _proposalStr;
  }
}