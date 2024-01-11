// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract MultiOwnable is Context {
	address[] private _owners;
	mapping(address => bool) ownerMapping;

	address private mainOwner;

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() {
		_addOwner(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return mainOwner;
	}

	function getOwners() public view virtual returns (address[] memory) {
		return _owners;
	}

	function setMainOwner(address add) public virtual onlyOwner {
		mainOwner = add;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(ownerMapping[_msgSender()] == true, 'Caller is not the owner');
		_;
	}

	function addOwner(address add) public virtual onlyOwner {
		_owners.push(add);
		ownerMapping[add] = true;
	}

  function _addOwner(address add) internal virtual {
		_owners.push(add);
		ownerMapping[add] = true;
    mainOwner = _msgSender();
	}

	function renounceOwnership() public virtual onlyOwner {
    removeOwnership(_msgSender());
	}

  function removeOwnership(address add) public virtual onlyOwner {
    removeAddressFromOwners(add);
    delete ownerMapping[add];
  }

	function removeAddressFromOwners(address addToRemove)
		internal
	{
    require(_owners.length > 1, "Cannot remove the only owner.");
		address[] memory oldOwners = _owners;
    delete _owners;
    // address[] memory newOwners = _owners;

		for (uint256 i = 0; i < oldOwners.length; i++) {
			if (oldOwners[i] != addToRemove) {
				_owners.push(oldOwners[i]);
			}
		}

    if(addToRemove == mainOwner){
      mainOwner = _owners[0];
    }
	}
}
