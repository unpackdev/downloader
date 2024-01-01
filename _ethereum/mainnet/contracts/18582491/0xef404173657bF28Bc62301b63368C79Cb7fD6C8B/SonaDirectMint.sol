// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

import "./ISonaRewardToken.sol";
import "./AddressableTokenId.sol";
import "./SonaTokenAuthorizor.sol";

/// @title SonaDirectMint
/// @author @SonaEngineering
contract SonaDirectMint is SonaTokenAuthorizor {
	using AddressableTokenId for uint256;

	/*//////////////////////////////////////////////////////////////
	/                         STATE
	//////////////////////////////////////////////////////////////*/

	// @dev The instance of the rewardToken contract
	ISonaRewardToken public token;

	/*//////////////////////////////////////////////////////////////
	/                         MODIFIERS
	//////////////////////////////////////////////////////////////*/

	/// @dev ensure the provided signature is from the authorizor
	modifier bundlesAuthorized(
		ISonaRewardToken.TokenMetadata[] calldata _metadatas,
		Signature calldata _signature
	) {
		if (!_verify(_metadatas, _signature.v, _signature.r, _signature.s))
			revert SonaAuthorizor_InvalidSignature();
		_;
	}

	/*//////////////////////////////////////////////////////////////
								Constructor
	//////////////////////////////////////////////////////////////*/
	constructor(ISonaRewardToken _token, address authorizor_) {
		token = _token;
		_authorizor = authorizor_;

		_DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				_EIP712DOMAIN_TYPEHASH,
				keccak256("SonaDirectMint"), // name
				keccak256("1"), // version
				block.chainid, // chain ID
				address(this) // verifying contract
			)
		);
	}

	/*//////////////////////////////////////////////////////////////
	/                         FUNCTIONS
	//////////////////////////////////////////////////////////////*/

	/// @notice mint multiple SonaRewardTokens
	/// @param _metadatas array of tokens and info to be minted
	/// @param _signature the signature of the array of TokenMetadata objects
	function mint(
		ISonaRewardToken.TokenMetadata[] calldata _metadatas,
		Signature calldata _signature
	) external bundlesAuthorized(_metadatas, _signature) {
		token.mintMultipleToArtist(_metadatas);
	}
}
