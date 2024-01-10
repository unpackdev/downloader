/// SPDX-License-Identifier: CC-BY-2.5
pragma solidity 0.8.9;
import "./Ownable.sol"; // OZ: Ownership
import "./ERC721Enumerable.sol"; // OZ: ERC721Enumerable
import "./ERC721.sol";
import "./IERC2981.sol";

contract UniosNft is ERC721, ERC721Enumerable, Ownable, IERC2981 {
	/// ============ NFT Details ============
	address public constant ELECTRIC_COFFIN_WALLET = 0x0aC175E2f719Ea878Ae6F78209b63C9644A11d38;
	address public constant TEAM_MULTISIG = 0xcAcC3eBb4538313a8b1A5B01593bb5117BB285d4;
	uint256 public constant MINT_COST = 0.1 ether;
	uint256 public constant MAX_SUPPLY = 2500;
	uint256 public constant MAX_MINT_PRESALE = 3;
	uint256 public constant MAX_MINT = 10;

	string private baseURI_;
	bool public saleActive = false;

	/// ============ Royalty Details ============
	struct RoyaltyInfo {
		address recipient;
		uint24 amount;
	}

	RoyaltyInfo private _royalties;

	/// @notice bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

	/// @notice address to number of mints entries
	mapping(address => uint256) public mintsPerAddress;
	/// @notice addresses whitelisted for presale - mint presale for full cost
	mapping(address => bool) public whitelist;
	/// @notice addresses partners - free to mint, only pay gas fees
	mapping(address => bool) public partnerWhitelist;

	/// ============ Events ============
	/// @notice Emitted when royalty is successfully set
	/// @param receiver asddress of minting user
	/// @param royaltyAmount Number of mints by address
	event RoyaltySet(address receiver, uint256 royaltyAmount);

	/// ============ Constructor ============
	/// @param _royaltyAddress Royalty Contract Address
	/// @param _royaltyValue Royalty Value for each sale
	/// @param _nftName Name of the NFT
	/// @param _nftSymbol Symbol of the NFT
	/// @param _baseURI_ baseURI for NFT metadata
	constructor(
		address _royaltyAddress,
		uint256 _royaltyValue,
		address[10] memory _teamWallets,
		string memory _nftName,
		string memory _nftSymbol,
		string memory _baseURI_
	) ERC721(_nftName, _nftSymbol) {
		_setRoyalties(_royaltyAddress, _royaltyValue);
		baseURI_ = _baseURI_;

		uint count = 0;

		// mint 3 to each team member
		for (uint256 i = 0; i < _teamWallets.length; i++) {
			address member = _teamWallets[i];

			_safeMint(member, count);
			_safeMint(member, count + 1);
			_safeMint(member, count + 2);

			count += 3;
		}

		uint256 currentSupply = totalSupply();

		// 25 for electric coffin wallet - giveaways, etc
		for (uint256 i = 0; i < 25; i++) {
			_safeMint(ELECTRIC_COFFIN_WALLET, currentSupply + i);
		}
	}

	/// @notice partner mint - free to mint, only pay gas fees
	/// @param count number of NFTs for partner to mint
	function mintPartnerWhitelist(uint256 count) external {
		require(count <= 2, "only 2 NFTs allowed");
		require(partnerWhitelist[msg.sender], "exit");

		delete partnerWhitelist[msg.sender];

		mintsPerAddress[msg.sender] += count;
		require(mintsPerAddress[msg.sender] <= MAX_MINT, "max mints hit");

		uint256 currentSupply = totalSupply();
		require(currentSupply + count < MAX_SUPPLY, "Cannot exceed max supply");

		for (uint256 i = 0; i < count; i++) {
			_safeMint(msg.sender, currentSupply + i);
		}
	}

	/// @notice main sale mint function
	/// @param count number of NFTs or presale mint (max of 3)
	function mint(uint256 count) external payable {
		require(msg.value == MINT_COST * count, "insufficient funds");

		mintsPerAddress[msg.sender] += count;

		if (!saleActive) {
			require(whitelist[msg.sender], "not whitelisted");
			require(mintsPerAddress[msg.sender] <= MAX_MINT_PRESALE, "max presale mints hit");
		} else {
			require(mintsPerAddress[msg.sender] <= MAX_MINT, "max mints hit");
		}

		uint256 currentSupply = totalSupply();
		require(currentSupply + count < MAX_SUPPLY, "no more supply");

		for (uint256 i = 0; i < count; ++i) {
			_safeMint(msg.sender, currentSupply + i);
		}
	}

	function userMintCount(address user) external view returns (uint256) {
		return mintsPerAddress[user];
	}

	/// @dev See {IERC721Metadata-tokenURI}.
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI_;
	}

	/// @dev See {IERC721Metadata-tokenURI}.
	function setBaseURI(string memory _baseURI_) external onlyOwner {
		baseURI_ = _baseURI_;
	}

	/// @notice set the whitelist for presale minting
	/// @param addresses list of addresses to whitelist
	function setWhitelist(address[] calldata addresses) external onlyOwner {
		for (uint256 i = 0; i < addresses.length; i++) {
			whitelist[addresses[i]] = true;
		}
	}

	function setPartnerWhitelist(address[] memory addresses) external onlyOwner {
		for (uint256 i = 0; i < addresses.length; i++) {
			partnerWhitelist[addresses[i]] = true;
		}
	}

	function isWhitelisted(address addr) external view returns (bool) {
		return whitelist[addr];
	}

	function partnerIsWhitelisted(address addr) external view returns (bool) {
		return partnerWhitelist[addr];
	}

	function setSaleStatus(bool saleActive_) external onlyOwner {
		saleActive = saleActive_;
	}

	function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
		require(_exists(tokenId), "token does not exist.");

		RoyaltyInfo memory royalties = _royalties;
		receiver = royalties.recipient;
		royaltyAmount = salePrice * royalties.amount;
	}

	function _setRoyalties(address recipient, uint256 value) internal onlyOwner {
		require(value <= 10000, "ERC2981Royalties: Too high");

		_royalties = RoyaltyInfo(recipient, uint24(value));

		emit RoyaltySet(recipient, value);
	}

	/// @dev See {IERC165-supportsInterface}.
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
		return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, amount);
	}

	function withdraw() external onlyOwner {
		uint256 amount = address(this).balance;
		payable(TEAM_MULTISIG).transfer(amount);
	}
}
