pragma solidity 0.6.6;


/**
 * @author Simon Dosch
 * @title IOwnable
 * @dev IOwnable interface
 */
interface IOwnable {
	/**
	 * @dev Emitted when owership of the security token is transferred.
	 */
	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);
}
