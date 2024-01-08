// SPDX-License-Identifier: MIT

/// @title OMNI Token V4 / Ethereum v1
/// @author Alfredo Lopez / Arthur Miranda / OMNI App 2021.10 */

pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./Blacklistable.sol";

/**
 * @title Circulating Supply Methods
 * @dev Allows update the wallets of OMNI Foundation by Owner
 */
contract CirculatingSupply is OwnableUpgradeable, Blacklistable{
	// Array of address
    address[] internal omni_wallets;

    event InOmniWallet(address indexed _account);
    event OutOmniWallet(address indexed _account);

	/**
     * @dev function to verify if the address exist in OmniWallet or not
     * @param _account The address to check
     */
	function isOmniWallet(address _account) public view returns (bool) {
		if (_account == address(0)) {
			return false;
		}
		uint256 index = omni_wallets.length;
		for (uint256 i=0; i < index ; i++ ) {
			if (_account == omni_wallets[i]) {
				return true;			}
		}
		return false;
	}

	/**
     * @dev Include the wallet in the wallets address of OMNI Foundation Wallets
     * @param _account The address to include
     */
	function addOmniWallet(address _account) public validAddress(_account) onlyOwner() returns (bool) {
		require(!isOmniWallet(_account), "ERC20 OMN: wallet is already");
		omni_wallets.push(_account);
		emit InOmniWallet(_account);
		return true;
	}

	/**
     * @dev Exclude the wallet in the wallets address of OMNI Foundation Wallets
     * @param _account The address to exclude
     */
	function dropOmniWallet(address _account) public validAddress(_account) onlyOwner() returns (bool) {
		require(isOmniWallet(_account), "ERC20 OMN: Wallet don't exist");
		uint256 index = omni_wallets.length;
		for (uint256 i=0; i < index ; i++ ) {
			if (_account == omni_wallets[i]) {
				omni_wallets[i] = omni_wallets[index - 1];
				omni_wallets.pop();
				emit OutOmniWallet(_account);
				return true;
			}
		}
		return false;
	}

	/**
     * @dev Getting the all wallets address of OMNI Foundation Wallets
     */
	function getOmniWallets() public view returns (address[] memory) {
		return omni_wallets;
	}

}
