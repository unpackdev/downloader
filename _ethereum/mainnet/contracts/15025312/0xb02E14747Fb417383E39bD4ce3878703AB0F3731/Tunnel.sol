// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./ERC721Holder.sol";
import "./ISVG721.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/// @title Tunnel
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common functions.
/// @dev Encode and Decode functionality for L1 and L2.
contract Tunnel is ERC721Holder, Ownable, Pausable {
	address public Svg721Address;

	event SetSVG721(address Svg721Address);

	/// @param _Svg721Address Address of Svg721 contract
	function setSVG721(address _Svg721Address) external onlyOwner {
		Svg721Address = _Svg721Address;
		emit SetSVG721(Svg721Address);
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}

	///	@dev encode the data to send. Query the SVG721 contract for the same.
	///	@param tokenId id of token
	///	@param from sender
	function encode(uint256 tokenId, address from)
		public
		view
		returns (bytes memory message)
	{
		(string[] memory featureNames, uint256[] memory values) = ISVG721(
			Svg721Address
		).getAttributes(tokenId);
		message = abi.encode(
			from,
			tokenId,
			ISVG721(Svg721Address).metadata(tokenId),
			featureNames,
			values
		);
	}

	///	@dev encode the data received
	///	@param message received data
	function decode(bytes memory message)
		public
		pure
		returns (
			address from,
			uint256 tokenId,
			IBaseNFT.Metadata memory metadata,
			string[] memory featureNames,
			uint256[] memory values
		)
	{
		(from, tokenId, metadata, featureNames, values) = abi.decode(
			message,
			(address, uint256, IBaseNFT.Metadata, string[], uint256[])
		);
	}
}
