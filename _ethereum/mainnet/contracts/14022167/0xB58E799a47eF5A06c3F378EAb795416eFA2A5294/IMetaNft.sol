// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";

interface IMetaNft is IERC721 {
	function mint(address to, uint256 level, uint256 startIndex, uint256 minted) external returns (uint256);
	function burn(uint256 tokenId) external;
	function setBaseURI(string memory baseURI) external;
}
