//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";

/**
 *  @title Genesi Collection
 */
contract GenesiCollection is ERC721URIStorage, Ownable {
	using Strings for uint256;
	using SafeMath for uint256;

	string private baseURI;
	uint256 public maxPublicSupply;
	uint256 public totalSupply;
	uint256 public royaltyPercentage;

	/*********************************
	 *  EVENTS
	 *********************************/
	event RoyaltyPercentageChanged(uint256 indexed newPercentage);
	event BaseUriUpdated(string indexed uri);

	/*********************************
	 *  MODIFIERS
	 *********************************/

	modifier onlyNonexistentToken(uint256 _tokenId) {
		require(!_exists(_tokenId), "TOKEN_EXISTS");
		_;
	}

	/** @notice Initiator
     * @param tokenName The name of the NFT token
     * @param tokenSymbol The symbol of the NFT tokens
     * @param _baseUri The tokenURI base string
     * @param _royaltyPercentage Percentage of royalty to be taken per sale
     */
	constructor(
		string memory tokenName,
		string memory tokenSymbol,
		string memory _baseUri,
		uint256 _royaltyPercentage,
		uint256 _maxPublicSupply
	)
	ERC721(tokenName, tokenSymbol)
	{
		baseURI = _baseUri;
		royaltyPercentage = _royaltyPercentage;
		maxPublicSupply = _maxPublicSupply;
	}

	/** @notice Set baseURI for metafile root path
     *  @dev Emits "BaseUriUpdates"
     * @param uri The new uri for tokenURI bsae
     */
	function setBaseURI(string memory uri) external onlyOwner {
		baseURI = uri;
		emit BaseUriUpdated(baseURI);
	}

	/** @notice Sets royalty percentage for secondary sale
     * @dev Emits "RoyaltyPercentageChanged"
     * @param _percentage The percentage of royalty to be deducted
     */
	function setRoyaltyPercentage(uint256 _percentage) external onlyOwner {
		royaltyPercentage = _percentage;

		emit RoyaltyPercentageChanged(royaltyPercentage);
	}

	/** @notice  Mint NFT tokens
     * @param _id The id of the nft to be minted
     * @param destination The minted token receiver
     */
	function generate(uint256 _id, address destination)
	external
	onlyOwner
	onlyNonexistentToken(_id)
	{
		require(destination != address(0), "ADDRESS_CAN_NOT_BE_ZERO");
		require(totalSupply < maxPublicSupply, "MAX_PUBLIC_SUPPLY_REACHED");
		totalSupply = totalSupply.add(1);
		_safeMint(destination, _id);
	}

	/** @notice Provides information about the amount of royalty to be given and to whom
     * @param _price The price for the nft purchase/transaction being performed
     * @return royaltyAmount The amount of royalty to be paid
     * @return royaltyReceiver The destination where royalty has to be sent
     */
	function getRoyaltyInfo(uint256 _price)
	external
	view
	returns (uint256 royaltyAmount, address royaltyReceiver)
	{
		require(_price > 0, "PRICE_CAN_NOT_BE_ZERO");
		uint256 royalty = (_price.mul(royaltyPercentage)).div(100);

		return (royalty, owner());
	}

	/** @notice Provides token URI of the NFT
     * @param _tokenId The id of the specific NFT
     * @return The URI string for the token's metadata file
     */
	function tokenURI(uint256 _tokenId)
	public
	view
	override(ERC721URIStorage)
	returns (string memory)
	{
		require(_exists(_tokenId), "TOKEN_DOES_NOT_EXIST");

		/// @dev Convert string to bytes so we can check if it's empty or not.
		return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
	}

	/**
	 * @dev See {IERC721-transferFrom}.
     * @notice Only Trusted Marketplace contract can use
     */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		require(
			_isApprovedOrOwner(msg.sender, tokenId),
			"CALLER_NOT_APPROVED"
		);

		_transfer(from, to, tokenId);
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
     * @notice Only Trusted Marketplace contract can use
     */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public virtual override {
		require(
			_isApprovedOrOwner(msg.sender, tokenId),
			"CALLER_NOT_APPROVED"
		);
		_safeTransfer(from, to, tokenId, _data);
	}

	/// @dev Overridden function to prevent Owner from relinquishing Ownership by accident
	function renounceOwnership() public view override onlyOwner {
		revert("CAN_NOT_RENOUNCE_OWNERSHIP");
	}

	function approve(address to, uint256 tokenId) public virtual override {
		address tokenOwner = ERC721.ownerOf(tokenId);
		require(to != tokenOwner, "ERC721:APPROVAL_TO_CURRENT_OWNER");

		require(
			msg.sender == tokenOwner ||
			isApprovedForAll(tokenOwner, msg.sender),
			"ERC721:APPROVE_CALLER_NOT_OWNER_OR_APPROVED_FOR_ALL"
		);

		_approve(to, tokenId);
	}

	/**@dev Returns baseURI
     */

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}
}
