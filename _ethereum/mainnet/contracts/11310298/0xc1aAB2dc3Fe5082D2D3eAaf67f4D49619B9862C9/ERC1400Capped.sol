pragma solidity 0.6.6;

import "./Ownable.sol";
import "./IERC1400Capped.sol";


/**
 * @author Simon Dosch
 * @title ERC1400Capped
 * @dev Regulating the cap of the security token
 */
contract ERC1400Capped is IERC1400Capped, Ownable {
	/**
	 * @dev Returns the cap on the token's total supply.
	 */
	function cap() public override view returns (uint256) {
		return _cap;
	}

	/**
	 * @dev Sets cap to a new value
	 * New value need to be higher than old one
	 * Is only callable by CAP?_EDITOR
	 * @param newCap value of new cap
	 */
	function setCap(uint256 newCap) public override {
		require(hasRole(bytes32("CAP_EDITOR"), _msgSender()), "!CAP_EDITOR");
		require((newCap > _cap), "new cap needs to be higher");

		// set new cap
		_cap = newCap;
		emit CapSet(newCap);
	}
}
