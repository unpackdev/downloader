// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721ASafeMintable {
	function safeMint(address to, uint256 quantity) external;
}
