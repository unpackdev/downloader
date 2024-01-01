// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

interface ISonaTokenAuthorizor {
	/*//////////////////////////////////////////////////////////////
	/                       ERRORS
	//////////////////////////////////////////////////////////////*/

	/// @notice emitted when a signature recovery does not succeed
	error SonaAuthorizor_InvalidSignature();

	/*//////////////////////////////////////////////////////////////
	/                        STRUCTS
	//////////////////////////////////////////////////////////////*/

	/// @notice the an elliptic curve signature, provided by the authorizor
	struct Signature {
		uint8 v;
		bytes32 r;
		bytes32 s;
	}
}
