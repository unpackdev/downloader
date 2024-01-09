//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IRenderer interface
 * @author Tfs128.eth (@trickerfs128)
 */
interface IRenderer {
	function render(uint256 tokenId, uint256 dna) external view returns (string memory);
}