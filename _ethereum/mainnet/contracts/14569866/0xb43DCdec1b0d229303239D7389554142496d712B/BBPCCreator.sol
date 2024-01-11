// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @author Block Block Punch Click (blockblockpunchclick.com)

import "./ERC721A.sol";
import "./BetterBoolean.sol";
import "./SafeAddress.sol";
import "./ABDKMath64x64.sol";
import "./ContractGuardian.sol";
import "./LockedPaymentSplitter.sol";

import "./IERC1155.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./ERC165.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";

/// @dev Errors
/**
 * @notice Insufficient balance for transfer. Needed `required` but only `available` available.
 * @param available balance available.
 * @param required requested amount to transfer.
 */
error InsufficientBalance(uint256 available, uint256 required);
/**
 * @notice Maximum mints exceeded. Allowed `allowed` but trying to mint `trying`.
 * @param trying total trying to mint.
 * @param allowed allowed amount to mint per wallet.
 */
error MaxPerWalletCap(uint256 trying, uint256 allowed);
/**
 * @notice Maximum supply exceeded. Allowed `allowed` but trying to mint `trying`.
 * @param trying total trying to mint.
 * @param allowed allowed amount to mint per wallet.
 */
error MaxSupplyExceeded(uint256 trying, uint256 allowed);
/**
 * @notice Not allowed. Address is not allowed.
 * @param _address wallet address checked.
 */
error NotAllowed(address _address);
/**
 * @notice Token does not exist.
 * @param tokenId token id checked.
 */
error DoesNotExist(uint256 tokenId);

/**
 * @title BBPCCreator
 * @author Block Block Punch Click (blockblockpunchclick.com)
 * @dev Standard ERC721A implementation
 *
 * ERC721A NFT contract, with a presale phase (paid tokens).
 *
 * In addition to using ERC721A, gas is optimized via Merkle Trees, boolean packing
 * and use of constants where possible.
 */
abstract contract BBPCCreator is
	Context,
	Ownable,
	ContractGuardian,
	ReentrancyGuard,
	LockedPaymentSplitter,
	ERC721A
{
	enum Status {
		Pending,
		PreSale,
		PublicSale,
		Finished
	}

	using SafeAddress for address;
	using ABDKMath64x64 for uint;
	using BetterBoolean for uint256;
	using SafeMath for uint256;
	using Strings for uint256;
	using ECDSA for bytes32;

	Status public status;

	uint256 public constant MAX_PER_TRANSACTION = 9;
	uint256 public constant MAX_PER_WALLET_LIMIT = 500;

	string public baseURI;
	string public provenanceHash;
	uint256 public tokensReserved;
	uint256 public mintCost = 0.07 ether;

	uint256 public immutable reserveAmount;
	uint256 public immutable maxPresaleMint;
	uint256 public immutable maxPublicMint;
	uint256 public immutable maxBatchSize;
	uint256 public immutable maxSupply;
	bool public metadataRevealed;
	bool public metadataFinalised;

	mapping(address => uint256) private _mintedPerAddress;

	/// @dev Merkle root
	bytes32 internal rootHash;

	/// @dev Events
	event PermanentURI(string _value, uint256 indexed _id);
	event TokensMinted(address indexed mintedBy, uint256 indexed tokensNumber);
	event BaseUriUpdated(string oldBaseUri, string newBaseUri);
	event CostUpdated(uint256 oldCost, uint256 newCost);
	event PresaleListInitialized(address indexed admin, bytes32 rootHash);
	event ReservedToken(address minter, address recipient, uint256 amount);
	event StatusChanged(Status status);

	constructor(
		string memory __name,
		string memory __symbol,
		string memory __baseURI,
		uint256 _maxPresaleMint,
		uint256 _maxPublicMint,
		uint256 _maxSupply,
		uint256 _reserveAmount,
		address[] memory __addresses,
		uint256[] memory __splits
	) ERC721A(__name, __symbol) SlimPaymentSplitter(__addresses, __splits) {
		baseURI = __baseURI;
		maxPresaleMint = _maxPresaleMint;
		maxPublicMint = _maxPublicMint;
		maxSupply = _maxSupply;
		maxBatchSize = _maxPresaleMint > _maxPublicMint
			? _maxPresaleMint
			: _maxPublicMint;
		reserveAmount = _reserveAmount;
	}

	/**
	 * @dev Throws if presale is NOT active.
	 */
	function _isPresaleActive() internal view {
		if (_msgSender() != owner()) {
			require(status == Status.PreSale, "Presale is not active.");
		}
	}

	/**
	 * @dev Throws if public sale is NOT active.
	 */
	function _isPublicSaleActive() internal view {
		if (_msgSender() != owner()) {
			require(status == Status.PublicSale, "Public sale is not active.");
		}
	}

	/**
	 * @dev Throws if the sender is not on the presale list
	 */
	function _isOnPresaleList(bytes32[] memory proof) internal view {
		bool isOnList = MerkleProof.verify(
			proof,
			rootHash,
			keccak256(abi.encodePacked(_msgSender()))
		);
		if (
			status != Status.PreSale || !(isOnList || _msgSender() == owner())
		) {
			revert NotAllowed(_msgSender());
		}
	}

	/**
	 * @dev Throws if max tokens per wallet
	 */
	function _isMaxTokensPerWallet(uint256 quantity) internal view {
		if (_msgSender() != owner()) {
			uint256 mintedBalance = _mintedPerAddress[_msgSender()];
			uint256 currentMintingAmount = mintedBalance + quantity;
			if (currentMintingAmount > MAX_PER_WALLET_LIMIT) {
				revert MaxPerWalletCap(
					currentMintingAmount,
					MAX_PER_WALLET_LIMIT
				);
			}
		}
	}

	/**
	 * @dev Throws if the amount sent is not equal to the total cost.
	 */
	function _isCorrectAmountProvided(uint256 quantity) internal view {
		uint256 totalCost = quantity * mintCost;
		if (msg.value < totalCost && _msgSender() != owner()) {
			revert InsufficientBalance(msg.value, totalCost);
		}
	}

	/**
	 * @dev Throws if the claim size is not valid
	 */
	function _isValidBatchSize(uint256 count) internal view {
		require(
			0 < count && count <= maxBatchSize,
			"Max tokens per batch exceeded"
		);
	}

	/**
	 * @dev Throws if the total token number being minted is zero
	 */
	function _isMintingOne(uint256 quantity) internal pure {
		require(quantity > 0, "Must mint at least 1 token");
	}

	/**
	 * @dev Throws if the total token number being minted is zero
	 */
	function _isNotRevealed() internal view {
		require(!metadataRevealed, "Must not be revealed");
	}

	/**
	 * @dev Throws if the total being minted is greater than the max supply
	 */
	function _isLessThanMaxSupply(uint256 quantity) internal view {
		if (totalSupply() + quantity > maxSupply) {
			revert MaxSupplyExceeded(totalSupply() + quantity, maxSupply);
		}
	}

	/**
	 * @dev Handles refunding the buter if the value is greater than the mint cost
	 */
	function _refundIfOver(uint256 price) private {
		require(msg.value >= price, "Need to send more ETH.");
		if (msg.value > price) {
			payable(msg.sender).transfer(msg.value - price);
		}
	}

	/**
	 * @dev Mint function for reserved tokens.
	 */
	function _internalMintTokens(address minter, uint256 quantity) internal {
		_isLessThanMaxSupply(quantity);
		_safeMint(minter, quantity);
	}

	/**
	 * @notice Reserve token(s) to multiple team members.
	 *
	 * @param frens addresses to send tokens to
	 * @param quantity the number of tokens to mint.
	 */
	function reserve(address[] memory frens, uint256 quantity)
		external
		onlyOwner
	{
		_isMintingOne(quantity);
		_isValidBatchSize(quantity);
		_isLessThanMaxSupply(quantity);

		uint256 idx;
		for (idx = 0; idx < frens.length; idx++) {
			require(frens[idx] != address(0), "Zero address");
			_internalMintTokens(frens[idx], quantity);
			tokensReserved += quantity;
			emit ReservedToken(msg.sender, frens[idx], quantity);
		}
	}

	/**
	 * @notice Reserve multiple tokens to a single team member.
	 *
	 * @param fren address to send tokens to
	 * @param quantity the number of tokens to mint.
	 */
	function reserveSingle(address fren, uint256 quantity) external onlyOwner {
		_isMintingOne(quantity);
		_isValidBatchSize(quantity);
		_isLessThanMaxSupply(quantity);

		uint256 multiple = quantity / maxBatchSize;
		for (uint256 i = 0; i < multiple; i++) {
			_internalMintTokens(fren, maxBatchSize);
		}
		uint256 remainder = quantity % maxBatchSize;
		if (remainder != 0) {
			_internalMintTokens(fren, remainder);
		}
		tokensReserved += quantity;
		emit ReservedToken(msg.sender, fren, quantity);
	}

	/**
	 * @dev The presale mint function.
	 * @param quantity Total number of tokens to mint.
	 * @param proof Cryptographic proof checked to see if the wallet address is allowed.
	 */
	function mintPresale(uint256 quantity, bytes32[] memory proof)
		public
		payable
		nonReentrant
		onlyUsers
	{
		_isMintingOne(quantity);
		_isOnPresaleList(proof);
		_isMaxTokensPerWallet(quantity);
		_isCorrectAmountProvided(quantity);
		_isLessThanMaxSupply(quantity);

		if (_msgSender() != owner()) {
			_mintedPerAddress[_msgSender()] += quantity;
		}

		// _safeMint's second argument now takes in a quantity, not a tokenId.
		_safeMint(msg.sender, quantity);
		if (_msgSender() != owner()) {
			_refundIfOver(mintCost * quantity);
		}
		emit TokensMinted(_msgSender(), quantity);
	}

	/**
	 * @dev The public mint function.
	 * @param quantity Total number of tokens to mint.
	 */
	function mint(uint256 quantity) public payable nonReentrant onlyUsers {
		_isPublicSaleActive();
		_isMaxTokensPerWallet(quantity);
		_isCorrectAmountProvided(quantity);
		_isMintingOne(quantity);
		_isLessThanMaxSupply(quantity);

		if (_msgSender() != owner()) {
			_mintedPerAddress[_msgSender()] += quantity;
		}

		// _safeMint's second argument now takes in a quantity, not a tokenId.
		_safeMint(msg.sender, quantity);
		if (_msgSender() != owner()) {
			_refundIfOver(mintCost * quantity);
		}

		emit TokensMinted(_msgSender(), quantity);
	}

	/**
	 * @dev Proves fair generation and distribution.
	 * @param _provenanceHash hash composed from all the hashes of all the NFTs, in order, with
	 * which you can verify that the set is the exact same as the ones that we’ve generated.
	 */
	function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
		_isNotRevealed();
		require(
			bytes(provenanceHash).length == 0,
			"Provenance hash already set"
		);
		provenanceHash = _provenanceHash;
	}

	/**
	 * @dev Set the presale list
	 * @param _rootHash Root hash of the Merkle tree
	 */
	function setPresaleList(bytes32 _rootHash) public onlyOwner {
		rootHash = _rootHash;
		emit PresaleListInitialized(_msgSender(), rootHash);
	}

	/**
	 * @dev Check to see if the address is on the presale list.
	 * @param claimer The address trying to claim the tokens.
	 * @param proof Merkle proof of the claimer.
	 */
	function onPresaleList(address claimer, bytes32[] memory proof)
		external
		view
		returns (bool)
	{
		return
			MerkleProof.verify(
				proof,
				rootHash,
				keccak256(abi.encodePacked(claimer))
			);
	}

	/**
	 * @dev Set the base URI for the tokens
	 * @param baseURI_ Base URI for the token
	 */
	function setBaseURI(string memory baseURI_) external onlyOwner {
		require(!metadataFinalised, "Metadata already revealed");

		string memory _currentURI = baseURI;
		baseURI = baseURI_;
		emit BaseUriUpdated(_currentURI, baseURI_);
	}

	/**
	 * @notice This is a mint cost override
	 * @dev Handles setting the mint cost
	 * @param _newCost is the new cost to associate with minting
	 */
	function setMintCost(uint256 _newCost) public onlyOwner {
		uint256 currentCost = mintCost;
		mintCost = _newCost;
		emit CostUpdated(currentCost, _newCost);
	}

	/**
	 * @dev Retrieves the token information
	 * @param tokenId is the token id to retrieve data for
	 */
	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(_exists(tokenId), "No token");
		string memory baseURI_ = _baseURI();
		require(bytes(baseURI_).length > 0, "Base unset");
		return
			metadataRevealed && bytes(baseURI_).length != 0
				? string(abi.encodePacked(baseURI_, tokenId.toString()))
				: baseURI_;
	}

	/**
	 * @dev Handles hiding the pre-reveal metadata and revealing the final metadata.
	 */
	function revealMetadata() public onlyOwner {
		require(bytes(provenanceHash).length > 0, "Provenance hash not set");
		require(!metadataRevealed, "Metadata already revealed");
		metadataRevealed = true;
	}

	/**
	 * @dev Handles updating the status
	 */
	function setStatus(Status _status) external onlyOwner {
		status = _status;
		emit StatusChanged(_status);
	}

	/**
	 * @dev Ensures the baseURI can no longer be set
	 */
	function finalizeMetadata() public onlyOwner {
		require(!metadataFinalised, "Metadata already finalised");
		metadataFinalised = true;
	}

	/**
	 * @dev Fetches the baseURI
	 */
	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function getOwnershipData(uint256 tokenId)
		external
		view
		returns (TokenOwnership memory)
	{
		return _ownershipOf(tokenId);
	}
}
