// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Identifiable Token
 *
 * @notice Marker interface for the smart contracts having TOKEN_UID public property,
 *      usually these are ERC20/ERC721/ERC1155 token smart contracts
 *
 * @dev TOKEN_UID is used as an enhancement to ERC165 and helps better identifying
 *      deployed smart contracts
 *
 * @author Basil Gorin
 */
interface IdentifiableToken {
	/**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 * @dev Example value: 0x0bcafe95bec2350659433fc61cb9c4fbe18719da00059d525154dfe0d6e8c8fd
	 */
	function TOKEN_UID() external view returns (uint256);
}
