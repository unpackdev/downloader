// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This works with the idea that marketplaces shouldn't be the one managing how royalties are sent to recipients
 *
 * Marketplaces should inquire if there are any royalties set for a token id
 * If yes, it should only send royalties to this contract (using onRoyaltiesReceived)
 * This contract is the one that knows how Royalties should be handled.
 *
 * Complexity of distributing royalties shouldn't be handled by the marketplace
 */
interface IERCWithRoyalties {
	/**
	 * @dev this is called by other contracts to send royalties for a given id
	 *
	 * @param id token id
	 */
	function getRoyalties(uint256 id) external view returns (uint256);

	/**
	 * @dev this is called by other contracts to send royalties for a given id
	 *
	 * @param id token id
	 * @return `bytes4(keccak256("onRoyaltiesReceived(uint256)"))`
	 */
	function onRoyaltiesReceived(uint256 id) external payable returns (bytes4);
}
