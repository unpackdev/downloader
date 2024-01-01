// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

import "./ISonaRewardToken.sol";
import "./SonaMinter.sol";
import "./ERC721.sol";
import "./IERC2981Upgradeable.sol";
import "./LibString.sol";
import "./AddressableTokenId.sol";
import "./ZeroCheck.sol";
import "./IBlockListRegistry.sol";

/// @title SonaRewardToken
/// @author @SonaEngineering
/// @notice The NFTs that represent rewards claims for a given track
/// 				in the Sona protocol
contract SonaRewardToken is SonaMinter, ISonaRewardToken, IERC2981 {
	using AddressableTokenId for uint256;
	using ZeroCheck for address;

	/*//////////////////////////////////////////////////////////////
	/                         STATE
	//////////////////////////////////////////////////////////////*/

	/// @dev the address specified by ERC 2981 that royalties should be sent to
	address internal _royaltyRecipient;
	// for use with https://etherscan.io/address/0x4fC5Da4607934cC80A0C6257B1F36909C58dD622#code
	address internal _blockListRegistry;
	string internal _uriBase;

	/*//////////////////////////////////////////////////////////////
	/                         MAPPINGS
	//////////////////////////////////////////////////////////////*/

	mapping(uint256 => ISonaRewardToken.RewardToken) public rewardTokens;

	/*//////////////////////////////////////////////////////////////
	/	                        MODIFIERS
	//////////////////////////////////////////////////////////////*/

	/// @dev Modifier that ensures the calling contract has the admin role
	///				or is the artist of the SONA
	modifier onlySonaAdminOrCreator(uint256 _tokenId) {
		if (_tokenId.getAddress() != msg.sender && !isSonaAdmin(msg.sender))
			revert SonaRewardToken_Unauthorized();
		_;
	}

	/// @dev Modifier that only allows the current holder of a token
	modifier onlyTokenHolder(uint256 _tokenId) {
		if (_ownerOf[_tokenId] != msg.sender) revert SonaRewardToken_Unauthorized();
		_;
	}

	/// @dev Modifier that ensures the tokenId has been minted
	modifier checkExists(uint256 _tokenId) {
		if (tokenIdExists(_tokenId)) {
			_;
		} else {
			revert SonaRewardToken_TokenIdDoesNotExist();
		}
	}

	/*//////////////////////////////////////////////////////////////
	/                         CONSTRUCTOR
	//////////////////////////////////////////////////////////////*/
	constructor() ERC721("", "") {
		_disableInitializers();
	}

	/*//////////////////////////////////////////////////////////////
	/                         FUNCTIONS
	//////////////////////////////////////////////////////////////*/

	/// @dev Initializes the contract during proxy construction
	/// @param _eoaAdmin the AccessControl admin
	/// @param royaltyRecipient_ the location to send NFT royalties as specified in ERC2981
	function initialize(
		string calldata _name,
		string calldata _symbol,
		address _eoaAdmin,
		address royaltyRecipient_,
		string calldata uriBase_
	) external override initializer {
		// Setup role for contract creator, otherwise subsequent checks will not work
		_setupRole(_ADMIN_ROLE, _eoaAdmin);
		_setRoleAdmin(_ADMIN_ROLE, _ADMIN_ROLE);
		SonaMinter.initializeMinterRole();

		// Initialize ERC721
		name = _name;
		symbol = _symbol;
		_royaltyRecipient = royaltyRecipient_;
		_uriBase = uriBase_;
	}

	/// @notice auth-guarded mint function
	/// @dev This is meant to be pluggable and allow for the updates to mint
	///  			logic as the protocol evolves
	/// @param _owner The address the token will me minted to
	/// @param _tokenId The ID of the token that will be minted
	/// @param _metadataId the arweave txId of the token metadata stored on arweave
	/// @param _payout the address to distribute funds to, potentially to split them with collaborators
	function mint(
		address _owner,
		uint256 _tokenId,
		string calldata _metadataId,
		address payable _payout
	) external onlySonaMinter {
		_mint(_owner, _tokenId);
		_setTokenMetadata(_tokenId, _metadataId, _payout);
	}

	/// @notice auth-guarded mint function
	/// @dev This is for artists to batch mint existing library to the protocol
	/// @param _metadatas The array tokens to be minted
	function mintMultipleToArtist(
		TokenMetadata[] calldata _metadatas
	) external onlySonaMinter {
		for (uint i = 0; i < _metadatas.length; i++) {
			_mint(_metadatas[i].tokenId.getAddress(), _metadatas[i].tokenId);
			_setTokenMetadata(
				_metadatas[i].tokenId,
				_metadatas[i].metadataId,
				_metadatas[i].payout
			);
		}
	}

	/// @notice checks the msg.sender to see if it is on the operator blocklist
	/// @param _from the owner of the the nft
	/// @param _to the recipient of the nft
	/// @param _id the tokenId of the nft to be transferred
	function transferFrom(
		address _from,
		address _to,
		uint256 _id
	) public override {
		_blockInvalidOperator(msg.sender);
		super.transferFrom(_from, _to, _id);
	}

	/// @notice checks if the operator `_operator` is on the blocklist
	/// @param _operator the entity granted permission to transfer tokens on behalf of the msg.sender
	/// @param _approved set or unset approval for all tokens held
	function setApprovalForAll(
		address _operator,
		bool _approved
	) public override {
		if (_approved) _blockInvalidOperator(_operator);
		super.setApprovalForAll(_operator, _approved);
	}

	/// @notice Updates the arweave transaction ID for the metadata for a given RewardToken
	/// @dev the arweave transaction id is returned by the tokenURI function
	/// @param _tokenId The ID of the token that will be updated
	/// @param _txId The metadata's IPFS CID
	function updateArweaveTxId(
		uint256 _tokenId,
		string calldata _txId
	) external checkExists(_tokenId) onlySonaAdminOrCreator(_tokenId) {
		_updateArweaveTxId(_tokenId, _txId);
	}

	/// @notice Updates the Payout address for a token `token` to `_payout`
	/// @dev the payoutAddress is utlized as a delegated recipient of rewards
	/// @param _tokenId The ID of the token that will be updated
	/// @param _payout The new payout address to be used. Set to address(0) if funds should be sent directly to the claimant
	function updatePayoutAddress(
		uint256 _tokenId,
		address payable _payout
	) external checkExists(_tokenId) onlyTokenHolder(_tokenId) {
		rewardTokens[_tokenId].payout = _payout;

		emit PayoutAddressUpdated(_tokenId, _payout);
	}

	/// @notice Updates the blocklist address to `_newList`
	/// @param _newList the new blocklist address
	function updateBlockListAddress(address _newList) external onlySonaAdmin {
		_blockListRegistry = _newList;
	}

	/// @notice Updates the URI base string
	/// @param uriBase_ the string,starting with "https://" and _not_ terminated with a trailing slash
	function updateUriBase(string calldata uriBase_) external onlySonaAdmin {
		_uriBase = uriBase_;
	}

	/// @notice Get a RewardToken's metadata from arweave for token `_tokenId`
	/// @param _tokenId The ID of the token to fetch
	function tokenURI(
		uint256 _tokenId
	)
		public
		view
		override(ERC721, ISonaRewardToken)
		checkExists(_tokenId)
		returns (string memory)
	{
		return
			string(
				abi.encodePacked(
					_uriBase,
					"/",
					LibString.toString(block.chainid),
					"/",
					LibString.toHexString(_tokenId),
					"/nft-metadata.json"
				)
			);
	}

	function contractURI() public view returns (string memory) {
		return
			string(
				abi.encodePacked(
					_uriBase,
					"/",
					LibString.toString(block.chainid),
					"/contract-metadata.json"
				)
			);
	}

	/// @notice Returns the metadata of the token `_tokenId`
	/// @param _tokenId The ID of the token to fetch
	function getRewardTokenMetadata(
		uint256 _tokenId
	) external view checkExists(_tokenId) returns (RewardToken memory metadata) {
		return rewardTokens[_tokenId];
	}

	/// @notice Returns the splits address of the RewardToken
	/// @param _tokenId The ID of the token to fetch
	function getRewardTokenPayoutAddr(
		uint256 _tokenId
	) external view checkExists(_tokenId) returns (address payable payout) {
		return rewardTokens[_tokenId].payout;
	}

	/// @notice Check if token `_tokenId` exists
	/// @param _tokenId The ID of the token to check
	/// @return exists a boolean
	function tokenIdExists(uint256 _tokenId) public view returns (bool exists) {
		return _ownerOf[_tokenId].isNotZero();
	}

	/// @notice returns ERC 2981 recipient address and amount owed for a
	/// 				given sale price
	/// @param _salePrice The amount a token was sold for
	function royaltyInfo(
		uint256 /*tokenId*/,
		uint256 _salePrice
	) external view returns (address receiver, uint256 royaltyAmount) {
		receiver = _royaltyRecipient;
		royaltyAmount = (_salePrice * 7) / 100;
	}

	/// @dev check if an interface specification is supported by this contract
	function supportsInterface(
		bytes4 _interfaceId
	) public view override(SonaMinter, IERC165) returns (bool supported) {
		return
			SonaMinter.supportsInterface(_interfaceId) ||
			_interfaceId == type(IERC2981).interfaceId;
	}

	/*//////////////////////////////////////////////////////////////
	/                    INTERNAL FUNCTIONS
	//////////////////////////////////////////////////////////////*/
	function _updateArweaveTxId(
		uint256 _tokenId,
		string calldata _txId
	) internal {
		rewardTokens[_tokenId].arTxId = _txId;

		emit RewardTokenArweaveTxIdUpdated({ tokenId: _tokenId, txId: _txId });
	}

	function _setTokenMetadata(
		uint256 _tokenId,
		string calldata _txId,
		address payable _payout
	) internal {
		rewardTokens[_tokenId] = RewardToken({ arTxId: _txId, payout: _payout });

		emit RewardTokenMetadataUpdated({
			tokenId: _tokenId,
			txId: _txId,
			payout: _payout
		});
	}

	function _isOperatorBlocked(address _operator) internal view returns (bool) {
		return
			_blockListRegistry != address(0) &&
			IBlockListRegistry(_blockListRegistry).isBlocked(_operator);
	}

	function _blockInvalidOperator(address _operator) internal view {
		if (_isOperatorBlocked(_operator)) {
			revert SonaRewardToken_OperatorNotAllowed(_operator);
		}
	}
}
