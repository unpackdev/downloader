// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC165.sol";
import "./Ownable.sol";

/// @title GameConnector
abstract contract GameConnector is Ownable, IERC165 {

	/// @dev Wen the caller is not allowed
	error CallerNotAllowed();

	/// @dev The address to the game;
	mapping(address => bool) private _allowedCallers;

	/// Assigns the address to the mapping of allowed callers
	/// @dev If assigning allowed to address(0), anyone may call the `onlyAllowedCallers` functions
	/// @param caller The address of the caller with which to assign allowed
	/// @param allowed Whether the `caller` will be allowed to call `onlyAllowedCallers` functions
	function assignAllowedCaller(address caller, bool allowed) external onlyOwner {
		if (allowed) {
			_allowedCallers[caller] = allowed;
		} else {
			delete _allowedCallers[caller];
		}
	}

	/// Prevents a function from executing if not called by an allowed caller
	modifier onlyAllowedCallers() {
		if (!_allowedCallers[_msgSender()] && !_allowedCallers[address(0)]) revert CallerNotAllowed();
		_;
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}

	/// @inheritdoc Ownable
	function transferOwnership(address newOwner) public virtual override {
		if (newOwner != owner()) {
			delete _allowedCallers[owner()];
		}
		super.transferOwnership(newOwner);
	}
}
