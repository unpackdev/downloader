// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";

interface INFTSport is IERC721, IERC721Enumerable {
  function nftToTeam(uint256 tokenId) external view returns (uint256);

  function mint(address account, uint256 tokenId) external returns (uint256);
}
