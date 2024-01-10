// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./ECDSA.sol";

import "./OwnableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IWalletRegistry {

	function isPairValid(address _fromAddress, address _toAddress) external view returns(bool isValid_);

	function getDelegate(address _owner) external view returns(address delegate_);

	function getOwner(address _delegate) external view returns(address owner_);
}

contract GutterArt is ERC1155BurnableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
	using Strings for uint256;
	using ECDSA for bytes32;

	uint256 public constant ETH = 0;
	uint256 public constant GANG = 1;

    struct DutchAuctionData {
        uint256 startPrice;
        uint256 endPrice;
        uint256 startDate;
        uint256 duration;
        uint256 currency;
    }

	address private minter;
	address private signer;

	IWalletRegistry private registry;

	bool public isMigrationEnabled;

	string private _baseTokenURI;
	string private _contractURI;

	mapping (string => bool) public nonceUsed;
	mapping (uint256 => bool) public allowedIds;

	mapping (uint256 => uint256) public ethPrices;
	mapping (uint256 => uint256) public gangPrices;

    mapping (uint256 => mapping(address => bool)) public userHasMinted;

    mapping (uint256 => DutchAuctionData) public dutchAuctions;

	IERC20 public gangToken;

	function initialize() public initializer {
		__ERC1155Burnable_init();
		__ERC1155_init(_baseTokenURI);
		__Ownable_init_unchained();
		__ReentrancyGuard_init();
	}

	function setup(
		address _signerAddress,
		string memory baseURI,
		string memory contractUri
	) external onlyOwner {
		minter = msg.sender;
		signer = _signerAddress;

		_baseTokenURI = baseURI;
		_contractURI = contractUri;
	}

	function adminMint(
		address receiver,
		uint256 nftID,
		uint256 quantity
	) external onlyOwner {
		require(quantity <= 50, "max 50 per mint");
		_mint(receiver, nftID, quantity, "");
	}

	function migrate(
		bytes memory signature,
		bytes32 hash,
		uint256 nftID,
		uint256 quantity,
		string memory nonce
	) external payable nonReentrant {
		require(allowedIds[nftID], "id is not allowed to mint");
		require(matchAddresSigner(hash, signature), "wrong signer");
		require(hashMigrate(msg.sender, nftID, quantity, nonce) == hash, "wrong hash");

        require(isMigrationEnabled, "minting disabled");
        require(!nonceUsed[nonce], "already used");
		require(quantity * ethPrices[nftID] == msg.value, "wrong price");

		_mint(msg.sender, nftID, quantity, "");
		nonceUsed[nonce] = true;
	}

    function mint(
		bytes memory signature,
		bytes32 hash,
		address to,
		uint256 nftID,
		uint256 quantity
	) external payable nonReentrant {
		require(allowedIds[nftID], "id is not allowed to mint");
		require(matchAddresSigner(hash, signature), "wrong signer");
		require(hashMint(msg.sender, to, nftID, quantity, ETH) == hash, "wrong hash");
		require(to == msg.sender, "can't mint to this address");

        require(!userHasMinted[nftID][to], "already used");
		require(quantity * ethPrices[nftID] == msg.value, "wrong price");

		_mint(to, nftID, quantity, "");
		userHasMinted[nftID][to] = true;
	}

	function mintWithGang(
		bytes memory signature,
		bytes32 hash,
		address to,
		uint256 nftID,
		uint256 quantity
	) external nonReentrant {
		require(allowedIds[nftID], "id is not allowed to mint");
		require(matchAddresSigner(hash, signature), "wrong signer");
		require(hashMint(msg.sender, to, nftID, quantity, GANG) == hash, "wrong hash");
		require(to == msg.sender, "can't mint to this address");

        require(!userHasMinted[nftID][to], "already used");

		uint256 price = quantity * gangPrices[nftID];
		require(address(gangToken) != address(0), "gang token address is not set");
		require(gangToken.balanceOf(msg.sender) >= price, "insufficient funds");

		require(gangToken.transferFrom(msg.sender, address(this), price), "transfer failed");

		_mint(to, nftID, quantity, "");
		userHasMinted[nftID][to] = true;
	}

	function airdrop(
		address[] memory receivers,
		uint256[] memory quantities,
		uint256[] memory NFTIDs,
		bytes[] memory datas
	) external {
		require(receivers.length == quantities.length, "arrays should be equal");
		require(receivers.length == NFTIDs.length, "arrays should be equal 2");
		require(msg.sender == minter, "only minter account can call this");
		require(receivers.length <= 50, "max 50 addresses per call");
		for (uint256 i = 0; i < receivers.length; i++) {
			_mint(receivers[i], NFTIDs[i], quantities[i], datas[i]);
		}
	}

    function auctionMint(
        bytes memory signature,
		bytes32 hash,
		address to,
		uint256 nftID,
		uint256 quantity
	) external payable nonReentrant {
		require(allowedIds[nftID], "id is not allowed to mint");
		require(matchAddresSigner(hash, signature), "wrong signer");
		require(hashMint(msg.sender, to, nftID, quantity, ETH) == hash, "wrong hash");
		require(to == msg.sender, "can't mint to this address");
		require(!userHasMinted[nftID][to], "user has already minted");

        require(dutchAuctions[nftID].startPrice != 0, "auction doesn't exist");
        require(dutchAuctions[nftID].currency == ETH, "wrong currency");
        require(block.timestamp >= dutchAuctions[nftID].startDate, "not started yet");

        uint256 costToMint = getAuctionPrice(nftID) * quantity;
		require(msg.value >= costToMint, "eth value incorrect");

		_mint(to, nftID, quantity, "");
		userHasMinted[nftID][to] = true;

		if (msg.value > costToMint) {
			(bool success, ) = msg.sender.call{ value: msg.value - costToMint }("");
			require(success, "Address: unable to send value, recipient may have reverted");
		}
    }

    function auctionMintGang(
        bytes memory signature,
		bytes32 hash,
		address to,
		uint256 nftID,
		uint256 quantity
	) external nonReentrant {
		require(allowedIds[nftID], "id is not allowed to mint");
		require(matchAddresSigner(hash, signature), "wrong signer");
		require(hashMint(msg.sender, to, nftID, quantity, GANG) == hash, "wrong hash");
		require(to == msg.sender, "can't mint to this address");
		require(!userHasMinted[nftID][to], "user has already minted");

        require(dutchAuctions[nftID].startPrice != 0, "auction doesn't exist");
        require(dutchAuctions[nftID].currency == GANG, "wrong currency");
        require(block.timestamp >= dutchAuctions[nftID].startDate, "not started yet");

        uint256 costToMint = getAuctionPrice(nftID) * quantity;
		require(gangToken.transferFrom(msg.sender, address(this), costToMint), "transfer failed");

		_mint(to, nftID, quantity, "");
		userHasMinted[nftID][to] = true;
    }

    function getAuctionPrice(uint256 nftID) public view returns (uint256) {
        DutchAuctionData memory auction = dutchAuctions[nftID];
		uint256 elapsed = auction.startDate > 0 ? block.timestamp - auction.startDate : 0;
		if (elapsed >= auction.duration) {
			return auction.endPrice;
		} else {
			uint256 currentPrice = ((auction.duration - elapsed) * auction.startPrice) /
				auction.duration;
			return currentPrice > auction.endPrice ? currentPrice : auction.endPrice;
		}
	}

    function setupAuction(
        uint256 id,
        uint256 startPrice,
        uint256 endPrice,
        uint256 startDate,
        uint256 duration,
        uint256 currency
    ) external onlyOwner {
        dutchAuctions[id] = DutchAuctionData(startPrice, endPrice, startDate, duration, currency);
    }

    function deleteAuction(uint256 id) external onlyOwner {
        delete dutchAuctions[id];
    }

	function setMinter(address _newMinter) external onlyOwner {
		minter = _newMinter;
	}

	function setMigrationEnabled(bool _enabled) external onlyOwner {
		isMigrationEnabled = _enabled;
	}

	function setGangAddress(address _gangAddress) external onlyOwner {
		gangToken = IERC20(_gangAddress);
	}

	function setETHPrice(uint256 id, uint256 price) external onlyOwner {
		ethPrices[id] = price;
	}

	function setGangPrice(uint256 id, uint256 price) external onlyOwner {
		gangPrices[id] = price;
	}

	// balance-related
	function withdrawETH() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function reclaimERC20(address _tokenContract, uint256 _amount) external onlyOwner {
		IERC20(_tokenContract).transfer(msg.sender, _amount);
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function reclaimERC1155(
		IERC1155 erc1155Token,
		uint256 id,
		uint256 amount
	) external onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, amount, "");
	}

	// metadata-related
	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
	}

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) external onlyOwner {
		_contractURI = newuri;
	}

	function setIDAllowed(uint256 id, bool allowed) public onlyOwner {
		allowedIds[id] = allowed;
	}

	function setIDRangeAllowed(uint256 start, uint256 end, bool allowed) public onlyOwner {
		for (uint256 i = start; i <= end; i++) {
			allowedIds[i] = allowed;
		}
	}

	function setRegistry(address _registry) external onlyOwner {
		registry = IWalletRegistry(_registry);
	}

	// utils
	function hashMigrate(
		address sender,
		uint256 id,
		uint256 qty,
		string memory nonce
	) private pure returns (bytes32) {
		return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(sender, id, qty, nonce)));
	}

	function hashMint(
		address sender,
		address to,
		uint256 id,
		uint256 qty,
		uint256 currency
	) private pure returns (bytes32) {
		return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(sender, to, id, qty, currency)));
	}

	function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
		return signer == hash.recover(signature);
	}

}