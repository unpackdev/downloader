pragma solidity 0.6.6;


/**
 * @title IERC1400Capped
 * @dev ERC1400Capped interface
 */
interface IERC1400Capped {
	/**
	 * @dev Returns the cap on the token's total supply.
	 */
	function cap() external view returns (uint256);

	/**
	 * @dev Sets cap to a new value
	 * New value need to be higher than old one
	 * Is only callable by CAP?_EDITOR
	 * @param newCap value of new cap
	 */
	function setCap(uint256 newCap) external;

	/**
	 * @dev Event emitted when a new cap is set
	 */
	event CapSet(uint256 newCap);
}
