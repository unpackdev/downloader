// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

//     _   _  _  ___  _  _
//    /_\ | \| |/ _ \| \| |
//   / _ \| .` | (_) | .` |
//  /_/ \_\_|\_|\___/|_|\_|
contract AnonRobin is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];

	bytes32 public root = 0x5acf04759ed79125d670f0fbdc9cf61b250f3e425c09202035fa2ed5c1f409c4;

	string public _contractBaseURI = "ipfs://to_be_updated_later/";
	string public _unrevealedURI = "ipfs://QmbDfyKz9DL4Q16H84EN53R3gqLP6N9ZHc9SSZWGfwZT5k";
	string public _contractURI = "ipfs://QmSfaNc72kWmKuM8sEUqReVAzSAst6nKdWgATjpGfaMnAn";

	uint256 public maxSupply = 333;
	uint256 public preSaleSupply = 333;

	bool public isRevealed = false;

	uint256 public presalePrice = 0.35 ether;
	uint256 public publicPrice = 0.4 ether;

	uint256 public presaleStartTime = 1648303200; // Saturday, March 26, 2022 2:00:00 PM UTC
	uint256 public publicStartTime = 1648396800; // Sunday, March 27, 2022 4:00:00 PM UTC

	mapping(address => uint256) public usedAddresses; //merkle root check

	//owner: 0x473Facf7c8A5e1330d660f0DeFa3CAc2ED528407
	//payment splitter
	address[] private addressList = [
		0xdceCfa99F6bb7e33C69e184c89A9B34E80D464f4,
		0xAEC39e71866b78A3C81916024Ad01ad266180598,
		0xCcCA636D47c55470896fAbD907191cdb64F4A5f2
	];
	uint256[] private shareList = [6, 13, 81];

	constructor() ERC721A("Anon Robin", "ARO") PaymentSplitter(addressList, shareList) {}

	/**
	 @dev admin can mint 33
	 @param to - destination
	 @param qty - quantity
	  */
	function adminMint(address to, uint256 qty) external onlyOwner {
		require(totalSupply() <= 33, "out of stock");
		_safeMint(to, qty);
	}

	/**
	 @dev only whitelisted can buy, maximum maxQty
	 @param qty - the quantity that a user wants to buy
	 @param limit - limit of the wallet
	 @param proof - merkle proof
	  */
	function presaleBuy(
		uint256 qty,
		uint256 limit,
		bytes32[] calldata proof
	) external payable nonReentrant {
		require(presalePrice * qty == msg.value, "exact amount needed");
		require(block.timestamp >= presaleStartTime, "not live");
		require(usedAddresses[msg.sender] + qty <= limit, "wallet limit reached");
		require(totalSupply() + qty <= preSaleSupply, "out of stock");
		require(isProofValid(msg.sender, limit, proof), "invalid proof");

		usedAddresses[msg.sender] += qty;
		_safeMint(msg.sender, qty);
	}

	/**
	 @dev everyone can buy
	  */
	function publicBuy() external payable nonReentrant {
		require(publicPrice == msg.value, "exact amount needed");
		require(totalSupply() <= maxSupply, "out of stock");
		require(block.timestamp >= publicStartTime, "not live");

		_safeMint(msg.sender, 1);
	}

	/**
	 * READ FUNCTIONS
	 */
	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		if (isRevealed) {
			return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
		} else {
			return _unrevealedURI;
		}
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	//merkle root check
	function isProofValid(
		address to,
		uint256 limit,
		bytes32[] memory proof
	) public view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(to, limit));
		return proof.verify(root, leaf);
	}

	/**
	 * ADMIN FUNCTIONS
	 */
	function setURIs(string memory newBaseURI, string memory unrevealed) external onlyOwner {
		_contractBaseURI = newBaseURI;
		_unrevealedURI = unrevealed;
	}

	function setContractURI(string memory newuri) external onlyOwner {
		_contractURI = newuri;
	}

	//recover lost erc20. getting them back chance very low
	function reclaimERC20Token(address erc20Token) external onlyOwner {
		IERC20(erc20Token).transfer(msg.sender, IERC20(erc20Token).balanceOf(address(this)));
	}

	//recover lost nfts. getting them back chance very low
	function reclaimERC721(address erc721Token, uint256 id) external onlyOwner {
		IERC721(erc721Token).safeTransferFrom(address(this), msg.sender, id);
	}

	//change the presale start time
	function setStartTimes(uint256 presale, uint256 publicSale) external onlyOwner {
		presaleStartTime = presale;
		publicStartTime = publicSale;
	}

	//owner reserves the right to change the price
	function changePricePerToken(uint256 newPresalePrice, uint256 newPublicPrice) external onlyOwner {
		presalePrice = newPresalePrice;
		publicPrice = newPublicPrice;
	}

	//only decrease it, no funky stuff
	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "decrease only");
		maxSupply = newMaxSupply;
	}

	//call this to reveal the jpegs
	function setBaseURIAndReveal(string memory newBaseURI) external onlyOwner {
		require(!isRevealed, "cannot un-reveal");
		isRevealed = true;
		_contractBaseURI = newBaseURI;
	}

	function setMerkleRoot(bytes32 _root) external onlyOwner {
		root = _root;
	}
}
