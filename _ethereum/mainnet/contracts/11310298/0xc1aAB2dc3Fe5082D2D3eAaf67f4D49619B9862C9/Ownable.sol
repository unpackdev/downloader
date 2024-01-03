pragma solidity 0.6.6;

import "./Pausable.sol";
import "./IOwnable.sol";


/**
 * @author Simon Dosch
 * @title Ownable
 * @dev modeled after @openzeppelin/contracts/access/Ownable.sol
 */
contract Ownable is IOwnable, Pausable {
	// EVENTS in IOwnable.sol

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view returns (address) {
		return _owner;
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual {
		require(hasRole(bytes32("ADMIN"), _msgSender()), "!ADMIN");
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}
