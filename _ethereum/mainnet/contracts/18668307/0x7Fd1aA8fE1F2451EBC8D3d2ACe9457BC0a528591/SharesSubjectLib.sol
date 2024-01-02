// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Spec.sol";
import "./ERC721SpecExt.sol";
import "./TradeableShares.sol";

/**
 * @title Shares Subject Library
 *
 * @notice Auxiliary functions to work with SharesSubject struct
 */
library SharesSubjectLib {
	/**
	 * @notice Determines current owner of the shares subject, which is a corresponding NFT owner
	 *
	 * @dev This function returns zero address if NFT doesn't exist, or even if NFT contract doesn't exist
	 *
	 * @param sharesSubject shares subject, owner of the curve
	 * @return address of the issuer, underlying NFT owner; or zero address
	 */
	function getSharesIssuer(TradeableShares.SharesSubject memory sharesSubject) internal view returns(address) {
		// we have to check if the address is callable, otherwise staticall would throw
		if(isCallable(sharesSubject.tokenAddress)) {
			// try to avoid an exception / failed call in the ownerOf function by checking NFT existence first
			// this is required *only* to avoid "partially failed" transaction display on etherscan
			{
				// we use staticcall instead of ABI function call to guaranty immutable call
				(bool success, bytes memory data) = sharesSubject.tokenAddress.staticcall{gas: 4900}(
					// MintableERC721 interface: function exists(uint256) external view returns(bool)
					abi.encodeWithSignature("exists(uint256)", sharesSubject.tokenId)
				);
				// only if the call was successful
				if(success) {
					// try to decode the result as a bool,
					// and if we know for sure token doesn't exist,
					if(!abi.decode(data, (bool))) {
						// just return zero address as a default result in case of any error
						return address(0);
					}
				}
			}

			// try to get the ERC721 owner of the underlying NFT
			{
				// we use staticcall instead of ABI function call to guaranty immutable call
				(bool success, bytes memory data) = sharesSubject.tokenAddress.staticcall{gas: 4900}(
					// ERC721 interface: function ownerOf(uint256) external view returns(address)
					abi.encodeWithSignature("ownerOf(uint256)", sharesSubject.tokenId)
				);
				// only if the call was successful
				if(success) {
					// try to decode the result as an address and return
					return abi.decode(data, (address));
				}
			}
		}

		// return the default zero address value in case of any errors
		return address(0);
	}

	/**
	 * @notice Determines the owner of the shares subject's underlying NFT collection
	 *
	 * @dev This function returns zero address if the underlying ERC721 contract is not OZ ownable
	 *      (doesn't have `owner()` function), doesn't exist, or if any other error occurs
	 *
	 * @param sharesSubject shares subject, owner of the curve
	 * @return address of the NFT collection owner (OZ ownable); or zero address
	 */
	function getCollectionOwner(TradeableShares.SharesSubject memory sharesSubject) internal view returns(address) {
		// we have to check if the address is callable, otherwise staticall would throw
		if(isCallable(sharesSubject.tokenAddress)) {
			// try to derive the owner via the OZ Ownable interface owner()
			// we use staticcall instead of ABI function call to guaranty immutable call
			(bool success, bytes memory data) = sharesSubject.tokenAddress.staticcall{gas: 4900}(
				// OZ Ownable interface: function owner() external view returns(address)
				abi.encodeWithSignature("owner()")
			);

			// only if the call was successful
			if(success) {
				// try to decode the result as an address and return
				return abi.decode(data, (address));
			}
		}

		// return the default zero address value in case of any errors
		return address(0);
	}

	/**
	 * @notice Calculates the keccak256 bytes32 key for the shares subject to be used in the mappings
	 *
	 * @param sharesSubject shares subject, owner of the curve
	 * @return keccak256 of the shares subject
	 */
	function getSharesKey(TradeableShares.SharesSubject memory sharesSubject) internal pure returns(bytes32) {
		// calculate the keccak256 from the concatenated internals of the SharesSubject struct
		return keccak256(abi.encode(sharesSubject.tokenAddress, sharesSubject.tokenId));
	}

	/**
	 * @notice Checks if two subjects - subject 1 and subject 2 - are equal
	 *      Returns false if any of the subjects is not initialized (have zero ERC721 address)
	 *
	 * @param sharesSubject1 subject 1
	 * @param sharesSubject2 subject 2
	 * @return true if subject 1 and subject 2 are equal
	 */
	function equals(
		TradeableShares.SharesSubject memory sharesSubject1,
		TradeableShares.SharesSubject memory sharesSubject2
	) internal pure returns(bool) {
		return sharesSubject1.tokenAddress != address(0)
			&& sharesSubject1.tokenAddress == sharesSubject2.tokenAddress
			&& sharesSubject1.tokenId == sharesSubject2.tokenId;
	}

	/**
	 * @notice Verifies if the shares subject contains a value; this function is useful
	 *      to check if the value in storage (mapping) was initialized
	 *
	 * @param sharesSubject the shares subject to check
	 * @return true if the subject has a value, false otherwise (zero value)
	 */
	function isZero(TradeableShares.SharesSubject memory sharesSubject) internal pure returns(bool) {
		return sharesSubject.tokenAddress == address(0) && sharesSubject.tokenId == 0;
	}

	/**
	 * @notice Checks if account can be called (is callable, already deployed contract)
	 *
	 * @dev Verifies if the bytecode on the specified address is present
	 *
	 * @param account an address to check
	 * @return true if address denotes already deployed callable contract
	 */
	function isCallable(address account) internal view returns(bool) {
		// This method relies on extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}
}
