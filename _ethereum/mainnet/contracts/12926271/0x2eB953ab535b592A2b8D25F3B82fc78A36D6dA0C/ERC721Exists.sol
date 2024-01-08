// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title ERC721-Exists Extension
 *
 * @notice Enriches ERC721 interface with an `exists()` function which
 *      checks if particular token exists
 *
 * @author Basil Gorin
 */
interface ERC721Exists {
	/**
	 * @notice Checks if token defined by its ID exists
	 *
	 * @notice Tokens can be managed by their owner or approved
	 *      accounts via `approve` or `setApprovalForAll`.
	 *
	 * @notice Tokens start existing when they are minted (`mint`),
	 *      and stop existing when they are burned (`burn`).
	 *
	 * @param tokenId token ID to check existence of
	 * @return true if token exists, false otherwise
	 */
	function exists(uint256 tokenId) external view returns (bool);
}
