// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./FxBaseRootTunnel.sol";
import "./IERC721.sol";

import "./Tunnel.sol";
import "./ISVG721.sol";

/// @title L1Tunnel
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common functions.
/// @dev For L1-L2 communication
contract L1Tunnel is FxBaseRootTunnel, Tunnel {
	constructor(
		address _checkpointManager,
		address _fxRoot,
		address _Svg721Address
	) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
		Svg721Address = _Svg721Address;
	}

	/// @param message received data
	/// @dev decodes the data received. Called internally by receiveMessage
	function _processMessageFromChild(bytes memory message)
		internal
		virtual
		override
	{
		(
			address to,
			uint256 tokenId,
			IBaseNFT.Metadata memory metadata,
			string[] memory featureNames,
			uint256[] memory values
		) = decode(message);

		IERC721(Svg721Address).safeTransferFrom(address(this), to, tokenId);

		ISVG721(Svg721Address).setMetadata(metadata, tokenId);

		uint256[] memory tokenIds = new uint256[](featureNames.length);
		for (uint256 index = 0; index < featureNames.length; index++) {
			tokenIds[index] = tokenId;
		}
		ISVG721(Svg721Address).updateFeatureValueBatch(
			tokenIds,
			featureNames,
			values
		);
	}

	/// @dev transfer a token from L1 to L2. Locks token here.
	/// @param tokenId id of token
	function transferToL2(uint256 tokenId) external whenNotPaused {
		bytes memory message = encode(tokenId, msg.sender);
		IERC721(Svg721Address).safeTransferFrom(
			msg.sender,
			address(this),
			tokenId
		);
		_sendMessageToChild(message);
	}
}
