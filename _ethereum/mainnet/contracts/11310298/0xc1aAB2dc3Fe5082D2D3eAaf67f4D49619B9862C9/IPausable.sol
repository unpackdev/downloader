pragma solidity 0.6.6;


/**
 * @author Simon Dosch
 * @title IPausable
 * @dev IPausable interface
 */
interface IPausable {
	/**
	 * @dev Emitted when the pause is triggered by a pauser (`account`).
	 */
	event Paused(address account);

	/**
	 * @dev Emitted when the pause is lifted by a pauser (`account`).
	 */
	event Unpaused(address account);
}
