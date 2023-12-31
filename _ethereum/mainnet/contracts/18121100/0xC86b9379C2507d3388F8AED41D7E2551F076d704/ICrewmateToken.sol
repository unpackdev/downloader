// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";


interface ICrewmateToken is IERC721Upgradeable {
  
  function mint(address _to, uint _tokenId) external;

  function burn(uint _tokenId) external;

  function ownerOf(uint256 tokenId) external override view returns (address);

  function transferFrom(address from, address to, uint256 tokenId) external override;
}
