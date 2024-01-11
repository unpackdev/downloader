// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Address.sol";

interface IERC20 {
	function transferFrom(
		address from,
		address to,
		uint256 tokens
	) external returns (bool success);
}

interface IERC721 {
	function ownerOf(uint256 _tokenId) external view returns (address _owner);

	function approve(address _to, uint256 _tokenId) external;

	function getApproved(uint256 _tokenId) external view returns (address);

	function isApprovedForAll(address _owner, address _operator)
		external
		view
		returns (bool);

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) external;

	function supportsInterface(bytes4) external view returns (bool);
}

contract MarketplaceStorage {
	using Address for address;
	IERC20 public acceptedToken;

	struct Order {
		// Order ID
		bytes32 id;
		// Owner of the NFT
		address seller;
		// NFT registry address
		address nftAddress;
		// Price (in wei) for the published item
		uint256 price;
		// Time when this sale ends
		uint256 expiresAt;
	}

	// From ERC721 registry assetId to Order (to avoid asset collision)
	mapping(address => mapping(uint256 => Order)) public orderByAssetId;

	uint256 public ownerCutPerMillion;

	bytes4 public constant InterfaceId_ValidateFingerprint =
		bytes4(keccak256("verifyFingerprint(uint256,bytes)"));

	bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

	/** ------------------------------------------------ */
	/** --------------------- Events ------------------- */
	/** ------------------------------------------------ */
	event OrderCreated(
		bytes32 id,
		uint256 indexed assetId,
		address indexed seller,
		address nftAddress,
		uint256 priceInWei,
		uint256 expiresAt
	);
	event OrderSuccessful(
		bytes32 id,
		uint256 indexed assetId,
		address indexed seller,
		address nftAddress,
		uint256 totalPrice,
		address indexed buyer
	);
	event OrderCancelled(
		bytes32 id,
		uint256 indexed assetId,
		address indexed seller,
		address nftAddress
	);
	event PriceUpdated(
		bytes32 id,
		uint256 indexed assetId,
		address indexed seller,
		address nftAddress,
		uint256 oldPrice,
		uint256 newPrice,
		uint256 expiresAt
	);
	event Received(address indexed recipient, uint256 amount);
	event Withdraw(address indexed recipient, uint256 amount);
	event WithdrawTo(address indexed recipient, uint256 amount);

	event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);

	function setAcceptedToken(address _acceptedToken) public {
		require(
			_acceptedToken.isContract(),
			"The accepted token address must be a deployed contract"
		);
		acceptedToken = IERC20(_acceptedToken);
	}
}
