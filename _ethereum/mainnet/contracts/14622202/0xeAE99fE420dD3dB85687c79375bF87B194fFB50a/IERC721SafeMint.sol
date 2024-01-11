// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

interface IERC721SafeMint is IERC721 {
	function safeMint(address to, uint256 id) external;
	function totalSupply() external view returns (uint256);
}
