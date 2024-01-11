// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MerkleProofUpgradeable.sol";
import "./Initializable.sol";

error WhitelistIsEnabled();
error WhitelistNotEnabled();

abstract contract Whitelist is Initializable {
	bytes32 internal merkleRoot;

	event WhitelistEnabled();
	event WhitelistDisabled();

	/** Whitelist contstructor (empty) */
	function __Whitelist_init() internal onlyInitializing {}

	function whitelisted() public view returns (bool) {
		return merkleRoot != bytes32(0);
	}

	modifier whenWhitelisted {
		if (!whitelisted()) revert WhitelistNotEnabled();
		_;
	}

	modifier whenNotWhitelisted {
		if (whitelisted()) revert WhitelistIsEnabled();
		_;
	}

	/**
	 * Checks if an account is whitelisted using the given proof
	 * @param _account Account to verify
	 * @param _merkleProof Proof to verify the account is in the merkle tree
	 */
	function _whitelisted(address _account, bytes32[] calldata _merkleProof) internal view returns (bool) {
		return MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_account)));
	}

	/**
	 * Enable the whitelist and set the merkle tree root
	 * @param _merkleRoot Whitelist merkle tree root hash
	 */
	function _enableWhitelist(bytes32 _merkleRoot) internal {
		if (whitelisted()) revert WhitelistIsEnabled();
		merkleRoot = _merkleRoot;
		emit WhitelistEnabled();
	}

	/**
	 * Disable the whitelist and clear the root hash
	 */
	function _disableWhitelist() internal {
		if (!whitelisted()) revert WhitelistNotEnabled();
		delete merkleRoot;
		emit WhitelistDisabled();
	}

	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;
}