//SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.0;

// Interface for Legionnaire token
interface ILegionnaire {
  
  function safeMint(address to, uint256 tokenId) external;

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external;
}
