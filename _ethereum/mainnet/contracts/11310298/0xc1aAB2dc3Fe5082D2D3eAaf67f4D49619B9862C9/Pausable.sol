pragma solidity 0.6.6;

import "./Constrainable.sol";
import "./IPausable.sol";


/**
 * @author Simon Dosch
 * @title Pausable
 * @dev modeled after @openzeppelin/contracts/utils/Pausable.sol
 */
contract Pausable is IPausable, Constrainable {
	// EVENTS in IPausable.sol

	/**
	 * @dev Returns true if the contract is paused, and false otherwise.
	 * @return bool True if the contract is paused
	 */
	function paused() public view returns (bool) {
		return _paused;
	}

	/**
	 * @dev Called by a pauser to pause, triggers stopped state.
	 */
	function pause() public {
		require(!_paused, "paused");
		require(hasRole(bytes32("PAUSER"), _msgSender()), "!PAUSER");
		_paused = true;
		emit Paused(_msgSender());
	}

	/**
	 * @dev Called by a pauser to unpause, returns to normal state.
	 */
	function unpause() public {
		require(_paused, "not paused");
		require(hasRole(bytes32("PAUSER"), _msgSender()), "!PAUSER");
		_paused = false;
		emit Unpaused(_msgSender());
	}
}
