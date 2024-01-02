// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

interface ISonaRewardToken {
	error SonaRewardToken_DoesNotExist();

	error SonaRewardToken_TokenIdDoesNotExist();

	error SonaRewardToken_Unauthorized();

	error SonaRewardToken_ArtistEditionEven();

	error SonaRewardToken_ArtistEditionOdd();

	error SonaRewardToken_NoArtistInTokenId();

	error SonaRewardToken_OperatorNotAllowed(address operator);

	/*//////////////////////////////////////////////////////////////
	/                              EVENTS
	//////////////////////////////////////////////////////////////*/

	/// @dev Emitted when a RewardToken's metadata is changed.
	/// @param tokenId The id of the token
	/// @param txId The cid of the RewardToken
	event RewardTokenArweaveTxIdUpdated(uint256 tokenId, string txId);

	/// @dev Emitted when a RewardToken's metadata is changed.
	/// @param tokenId The id of the token
	/// @param txId The cid of the RewardToken
	event RewardTokenMetadataUpdated(
		uint256 indexed tokenId,
		string txId,
		address payout
	);

	/// @dev Emitted when a RewardToken is removed.
	/// @param tokenId The id of the RewardToken
	event RewardTokenRemoved(uint256 indexed tokenId);

	/// @dev Emitted when a RewardToken minter is initialized
	/// @param owner The owner of the contract
	/// @param name The name of the contract
	/// @param symbol The symbol of the contract
	event Initialized(address owner, string name, string symbol);

	/// @dev Emitted when the payout address is updated. The address can be set to zero to payout the token holder
	/// @param tokenId The id of the token updated
	/// @param payout The payout address change
	event PayoutAddressUpdated(uint256 indexed tokenId, address payout);

	/*//////////////////////////////////////////////////////////////
	/                             STRUCTS
	//////////////////////////////////////////////////////////////*/

	struct RewardToken {
		/// @dev The hash of the Arweave transaction where the metadata is stored.
		string arTxId;
		/// @dev The address for sharing rewards with collaborators
		address payable payout;
	}

	// @dev the information composing the NFT for use onchain and offchain
	struct TokenMetadata {
		uint256 tokenId;
		address payable payout;
		string metadataId;
	}

	/*//////////////////////////////////////////////////////////////
	/                            FUNCTIONS
	//////////////////////////////////////////////////////////////*/

	function mint(
		address _owner,
		uint256 _tokenId,
		string calldata _metadataId,
		address payable _payout
	) external;

	function mintMultipleToArtist(TokenMetadata[] calldata _metadatas) external;

	function updateArweaveTxId(uint256 _tokenId, string calldata _TxId) external;

	function tokenURI(uint256 _tokenId) external view returns (string memory);

	function getRewardTokenMetadata(
		uint256 _tokenId
	) external view returns (RewardToken memory metadata);

	function getRewardTokenPayoutAddr(
		uint256 _tokenId
	) external view returns (address payable payout);

	function initialize(
		string memory _name,
		string memory _symbol,
		address _eoaAdmin,
		address _royaltyRecipient,
		string memory uriBase_
	) external;

	function tokenIdExists(uint256 _tokenId) external view returns (bool exists);
}
