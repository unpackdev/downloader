// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./IERC2981.sol";

import "./IERC2981Upgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract GutterMerchUpgradeable is ERC1155Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable {
    using Strings for uint256;
	using ECDSA for bytes32;

	struct SaleState {
		bool ethEnabled;
		bool gangEnabled;
		bool burnEnabled;
		bool whitelistedMint; // used for mint without restriction by token id in external collection
		bool publicMint; // used without any user restriction
		bool tokenRestrictedMint; // used for mint available only once per token id in external collection
		uint256 publicMintPrice; // for public mint
		uint256 publicMintPriceGang; // for public mint
		uint256 publicMintDrop;
		uint256 totalMinted;
		uint256 totalBurned;
		mapping (address => mapping (uint256 => bool)) usedTokens; // for token restricted mint
	}

	address private signerAddress;

	string private _baseURI;
	string private _contractURI;

	IERC20 public gangToken;	

	mapping (uint256 => SaleState) public saleStates;
	mapping (string => bool) private usedNonces;

	address private gutterCats;
	address private gutterRats;
	address private gutterPigeons;
	address private gutterDogs;
	address private gutterJuices;
	address private gutterClones;

	mapping (uint256 => uint256) public dropsMaxPerWallet; // drop id to max per mint in drop
	mapping (uint256 => mapping(address => uint256)) public publicMintedPerDrop; // how much the person minted in drop

	address public royalties;
    uint256 public royaltyBps;

    function initialize() public initializer {
        __ERC1155_init("");
		__Ownable_init();
		__ReentrancyGuard_init();
	}

	function whitelistedMint(
		bytes memory signature,
		bytes32 hash,
        uint256 id,
		uint256 qty,
		uint256 price,
		uint256 currency, // 1 - ETH, 2 - GANG
		string memory nonce,
		uint256 expiresAt
	) external payable nonReentrant {
		_validateWhitelistedMint(
			msg.sender,
			signature,
			hash,
			id,
			qty,
			price,
			currency,
			nonce,
			expiresAt
		);

		// ETH-specific validations
		require(currency == 1 && saleStates[id].ethEnabled, "incorrect currency");
		require(msg.value == price * qty, "incorrect price");

		_mint(msg.sender, id, qty, "");

		saleStates[id].totalMinted += qty;
		usedNonces[nonce] = true;
	}

	function whitelistedMintGang(
		bytes memory signature,
		bytes32 hash,
        uint256 id,
		uint256 qty,
		uint256 price,
		uint256 currency, // 1 - ETH, 2 - GANG
		string memory nonce,
		uint256 expiresAt
	) external nonReentrant {
		_validateWhitelistedMint(
			msg.sender,
			signature,
			hash,
			id,
			qty,
			price,
			currency,
			nonce,
			expiresAt
		);

		// GANG-specific validations
		require(currency == 2 && saleStates[id].gangEnabled, "incorrect currency");
		require(gangToken.balanceOf(msg.sender) >= price * qty, "insufficient balance");

		require(
			gangToken.transferFrom(msg.sender, address(this), price * qty),
			"gang transfer failed"
		);

		_mint(msg.sender, id, qty, "");

		saleStates[id].totalMinted += qty;
		usedNonces[nonce] = true;
	}

	function catOnlyMint(
		bytes memory signature,
		bytes32 hash,
        uint256 id,
		uint256 qty,
		uint256 price,
		uint256 currency, // 1 - ETH, 2 - GANG
		uint256 speciesId
	) external payable nonReentrant {
		_validateTokenRestrictedMint(
			msg.sender,
			signature,
			hash,
			id,
			qty,
			price,
			currency,
			gutterCats,
			speciesId
		);
		require(IERC1155(gutterCats).balanceOf(msg.sender, speciesId) > 0, "not the owner");
		require(!saleStates[id].usedTokens[gutterCats][speciesId], "NFT is used");

		// ETH-specific validations
		require(currency == 1 && saleStates[id].ethEnabled, "incorrect currency");
		require(msg.value == price * qty, "incorrect price");

		_mint(msg.sender, id, qty, "");

		saleStates[id].totalMinted += qty;
		saleStates[id].usedTokens[gutterCats][speciesId] = true;
	}

	function publicMint(uint256 id, uint256 qty) external payable nonReentrant {
		_validatePublicMint(
			msg.sender,
			id,
			qty
		);

		// ETH-specific validations
		require(saleStates[id].ethEnabled, "incorrect currency");
		require(msg.value == saleStates[id].publicMintPrice * qty, "incorrect price");

		_mint(msg.sender, id, qty, "");

		saleStates[id].totalMinted += qty;
		uint256 dropId = saleStates[id].publicMintDrop;
		publicMintedPerDrop[dropId][msg.sender] += qty;
	}

	function publicMintGang(uint256 id, uint256 qty) external nonReentrant {
		_validatePublicMint(
			msg.sender,
			id,
			qty
		);

		require(saleStates[id].gangEnabled, "incorrect currency");
		require(
			gangToken.balanceOf(msg.sender) >= saleStates[id].publicMintPriceGang * qty, 
			"insufficient balance"
		);

		require(
			gangToken.transferFrom(msg.sender, address(this), saleStates[id].publicMintPriceGang * qty),
			"gang transfer failed"
		);
		
		_mint(msg.sender, id, qty, "");

		saleStates[id].totalMinted += qty;
		uint256 dropId = saleStates[id].publicMintDrop;
		publicMintedPerDrop[dropId][msg.sender] += qty;
	}

	// mint validations
	function _validateWhitelistedMint(
		address sender,
		bytes memory signature,
		bytes32 hash,
        uint256 id,
		uint256 qty,
		uint256 price,
		uint256 currency, // 1 - ETH, 2 - GANG
		string memory nonce,
		uint256 expiresAt
	) internal view {
		require(saleStates[id].whitelistedMint, "mint option not enabled");

		bytes32 resultHash = ECDSA.toEthSignedMessageHash(
			keccak256(abi.encodePacked(sender, id, qty, price, currency, nonce, expiresAt))
		);
		require(resultHash == hash, "invalid hash");
        require(ECDSA.recover(hash, signature) == signerAddress, "wrong signer");

		require(!usedNonces[nonce], "nonce is used");
		require(expiresAt >= block.timestamp, "mint data expired");
	}

	function _validateTokenRestrictedMint(
		address sender,
		bytes memory signature,
		bytes32 hash,
        uint256 id,
		uint256 qty,
		uint256 price,
		uint256 currency, // 1 - ETH, 2 - GANG
		address speciesContract,
		uint256 speciesId
	) internal view {
		require(saleStates[id].tokenRestrictedMint, "mint option not enabled");

		bytes32 resultHash = ECDSA.toEthSignedMessageHash(
			keccak256(abi.encodePacked(
				sender, id, qty, price, currency, speciesContract, speciesId
			))
		);
		require(resultHash == hash, "invalid hash");
        require(ECDSA.recover(hash, signature) == signerAddress, "wrong signer");
	}

	function _validatePublicMint(
		address sender,
		uint256 id,
		uint256 qty
	) internal view {
		require(saleStates[id].publicMint, "mint option not enabled");
		uint256 dropId = saleStates[id].publicMintDrop;
		require(publicMintedPerDrop[dropId][sender] + qty <= dropsMaxPerWallet[dropId], "max per wallet exceeded");
	}

	// merch redeeming
	function burn(
		address account,
		uint256 id,
		uint256 qty
	) external {
		require(saleStates[id].burnEnabled, "burn is not enabled");
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		require(balanceOf(account, id) >= qty, "balance too low");

		_burn(account, id, qty);

		saleStates[id].totalBurned = saleStates[id].totalBurned + qty;
	}

	function setDropMaxPerWallet(uint256 dropId, uint256 maxPerWallet) external onlyOwner {
		dropsMaxPerWallet[dropId] = maxPerWallet;
	}

	// price and sale setting functions
	function setSaleState(
		uint256 id,
		bool _ethEnabled,
		bool _gangEnabled,
		bool _burnEnabled,
		bool _whitelistedMint,
		bool _publicMint,
		bool _tokenRestrictedMint,
		uint256 _publicMintPrice,
		uint256 _publicMintPriceGang,
		uint256 _publicMintDrop
	) external onlyOwner {
		saleStates[id].ethEnabled = _ethEnabled;
		saleStates[id].gangEnabled = _gangEnabled;
		saleStates[id].burnEnabled = _burnEnabled;
		saleStates[id].whitelistedMint = _whitelistedMint;
		saleStates[id].publicMint = _publicMint;
		saleStates[id].tokenRestrictedMint = _tokenRestrictedMint;
		saleStates[id].publicMintPrice = _publicMintPrice;
		saleStates[id].publicMintPriceGang = _publicMintPriceGang;
		saleStates[id].publicMintDrop = _publicMintDrop;
	}

	function setSaleStateForRange(
		uint256[] memory ids,
		bool _ethEnabled,
		bool _gangEnabled,
		bool _burnEnabled,
		bool _whitelistedMint,
		bool _publicMint,
		bool _tokenRestrictedMint,
		uint256 _publicMintPrice,
		uint256 _publicMintPriceGang,
		uint256 _publicMintDrop
	) external onlyOwner {
		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			saleStates[id].ethEnabled = _ethEnabled;
			saleStates[id].gangEnabled = _gangEnabled;
			saleStates[id].burnEnabled = _burnEnabled;
			saleStates[id].whitelistedMint = _whitelistedMint;
			saleStates[id].publicMint = _publicMint;
			saleStates[id].tokenRestrictedMint = _tokenRestrictedMint;
			saleStates[id].publicMintPrice = _publicMintPrice;
			saleStates[id].publicMintPriceGang = _publicMintPriceGang;
			saleStates[id].publicMintDrop = _publicMintDrop;
		}
	}

	function setWhitelistedMintLiveForRange(
		uint256[] memory ids,
		bool _whitelistedMint
	) external onlyOwner {
		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			saleStates[id].whitelistedMint = _whitelistedMint;
		}
	}

	function setTokenRestrictedMintLiveForRange(
		uint256[] memory ids,
		bool _tokenRestrictedMint
	) external onlyOwner {
		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			saleStates[id].tokenRestrictedMint = _tokenRestrictedMint;
		}
	}

	function setPublicMintLiveForRange(
		uint256[] memory ids,
		bool _publicMint
	) external onlyOwner {
		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			saleStates[id].publicMint = _publicMint;
		}
	}

	function setEthEnabledForRange(
		uint256[] memory ids,
		bool _ethEnabled
	) external onlyOwner {
		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			saleStates[id].ethEnabled = _ethEnabled;
		}
	}

	function setGangEnabledForRange(
		uint256[] memory ids,
		bool _gangEnabled
	) external onlyOwner {
		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			saleStates[id].gangEnabled = _gangEnabled;
		}
	}

	function setBurnEnabledForRange(
		uint256[] memory ids,
		bool _burnEnabled
	) external onlyOwner {
		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			saleStates[id].burnEnabled = _burnEnabled;
		}
	}	

	function whitelistedMintLive(uint256 id) public view returns (bool) {
		return saleStates[id].whitelistedMint;
	}

	function tokenRestrictedMintLive(uint256 id) public view returns (bool) {
		return saleStates[id].tokenRestrictedMint;
	}

	function publicMintLive(uint256 id) public view returns (bool) {
		return saleStates[id].publicMint;
	}

	function burnLiveById(uint256 id) public view returns (bool) {
		return saleStates[id].burnEnabled;
	}

	function totalMinted(uint256 id) external view returns (uint256) {
		return saleStates[id].totalMinted;
	}

	function totalBurned(uint256 id) external view returns (uint256) {
		return saleStates[id].totalBurned;
	}

	function isTokenUsed(uint256 id, address contractAddress, uint256 tokenId) external view returns (bool) {
		return saleStates[id].usedTokens[contractAddress][tokenId];
	}

	// metadata-related functions
	function setBaseURI(string memory newuri) external onlyOwner {
		_baseURI = newuri;
	}

	function setContractURI(string memory newuri) external onlyOwner {
		_contractURI = newuri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, tokenId.toString()));
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	// reclaim accidentally sent tokens
	function reclaimERC20(IERC20 token) external onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

	function reclaimERC1155(IERC1155 erc1155Token, uint256 id) external onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, 1, "");
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	// admin functions
	function setupSigner(address _signerAddress) external onlyOwner {
		signerAddress = _signerAddress;
	}

	function setupRoyalties(
		uint256 _royaltyBps,
		address _royalties
	) external onlyOwner {
		royalties = _royalties;
		royaltyBps = _royaltyBps;
	}

	function setupGutterCollections(
		address _gutterCats,
		address _gutterRats,
		address _gutterPigeons,
		address _gutterDogs,
		address _gutterJuices,
		address _gutterClones
	) external onlyOwner {
		gutterCats = _gutterCats;
		gutterRats = _gutterRats;
		gutterPigeons = _gutterPigeons;
		gutterDogs = _gutterDogs;
		gutterJuices = _gutterJuices;
		gutterClones = _gutterClones;
	}

	function setGangToken(address _gangToken) external onlyOwner {
		gangToken = IERC20(_gangToken);
	}

	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function adminMint(
		address to,
		uint256 id,
		uint256 qty
	) external onlyOwner {
		_mint(to, id, qty, "");
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view override(ERC1155Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice * royaltyBps) / 10000 ;
        return (royalties, royaltyAmount);
    }
}