// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC1155Supply.sol";

//     _   _  _  ___  _  _
//    /_\ | \| |/ _ \| \| |
//   / _ \| .` | (_) | .` |
//  /_/ \_\_|\_|\___/|_|\_|
contract AnonRobinPasses is ERC1155Supply, Ownable, ReentrancyGuard, PaymentSplitter {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];

	bytes32 public root = 0xd3d3e3f5ad77f6411b8cce18b395ebe4f09573c63ba5c995bd30170dc9870f5a;

	string public _baseURI = "ipfs://QmS29CUssCWqvJ74w5xG5pm3xWEURhibbtGyqg85As8cBr/";
	string public _contractURI = "ipfs://QmZZn9XENnzG55FD15jh9GRkLQ3Extaa3VM5fKwskVxABk";

	uint256 public presaleStartTime = 1648303200; // Saturday, March 26, 2022 2:00:00 PM UTC
	uint256 public publicStartTime = 1648396800; // Sunday, March 27, 2022 4:00:00 PM UTC

	mapping(uint256 => uint256) public pricesPresale;
	mapping(uint256 => uint256) public pricesPresaleBulk;
	mapping(uint256 => uint256) public prices;
	mapping(uint256 => uint256) public maxSuppliesPresale;
	mapping(uint256 => uint256) public maxSupplies;
	mapping(address => uint256) public usedAddresses; //merkle root check

	uint256 private publicSaleKey;

	//owner: 0x473Facf7c8A5e1330d660f0DeFa3CAc2ED528407
	//payment splitter
	address[] private addressList = [
		0xdceCfa99F6bb7e33C69e184c89A9B34E80D464f4,
		0xAEC39e71866b78A3C81916024Ad01ad266180598,
		0xCcCA636D47c55470896fAbD907191cdb64F4A5f2
	];
	uint256[] private shareList = [6, 13, 81];

	constructor() ERC1155(_baseURI) PaymentSplitter(addressList, shareList) {
		maxSuppliesPresale[1] = 1035;
		maxSupplies[1] = 1035;

		pricesPresale[1] = 0.25 ether;
		pricesPresaleBulk[1] = 0.4 ether;
		prices[1] = 0.3 ether;
	}

	/**
	 @dev only whitelisted can buy, maximum 1
	 @param id - the ID of the token (eg: 1)
	 @param proof - merkle proof
	  */
	function presaleBuy(uint256 id, bytes32[] calldata proof) external payable nonReentrant {
		require(pricesPresale[id] != 0, "not live");
		require(pricesPresale[id] == msg.value, "exact amount needed");
		require(block.timestamp >= presaleStartTime, "not live");
		require(usedAddresses[msg.sender] + 1 <= 1, "wallet limit reached");
		require(totalSupply(id) + 1 <= maxSuppliesPresale[id], "out of stock");
		require(isProofValid(msg.sender, 1, proof), "invalid proof");

		usedAddresses[msg.sender] += 1;
		_mint(msg.sender, id, 1, "");
	}

	/**
	 @dev only whitelisted can buy, maximum 2
	 @param id - the ID of the token (eg: 1)
	 @param proof - merkle proof
	  */
	function presaleBulkBuy(uint256 id, bytes32[] calldata proof) external payable nonReentrant {
		require(pricesPresaleBulk[id] != 0, "not live");
		require(pricesPresaleBulk[id] == msg.value, "exact amount needed");
		require(block.timestamp >= presaleStartTime, "not live");
		require(usedAddresses[msg.sender] + 1 <= 1, "wallet limit reached");
		require(totalSupply(id) + 2 <= maxSuppliesPresale[id], "out of stock");
		require(isProofValid(msg.sender, 1, proof), "invalid proof");

		usedAddresses[msg.sender] += 2; //doesn't matter
		_mint(msg.sender, id, 2, "");
	}

	/**
	 @dev everyone can buy
	 @param qty - the quantity that a user wants to buy
	  */
	function publicBuy(uint256 id, uint256 qty) external payable nonReentrant {
		require(prices[id] != 0, "not live");
		require(prices[id] * qty == msg.value, "exact amount needed");
		require(qty <= 5, "max 5 at once");
		require(totalSupply(id) + qty <= maxSupplies[id], "out of stock");
		require(block.timestamp >= publicStartTime, "not live");

		_mint(msg.sender, id, qty, "");
	}

	/**
	 @dev admin can mint max 10 of each ID
	 @param to - destomatopm
	 @param id - the token ID
	 @param qty - the quantity
	  */
	function adminMint(
		address to,
		uint256 id,
		uint256 qty
	) external onlyOwner {
		require(totalSupply(id) + qty <= 10, "out of stock");
		_mint(to, id, qty, "");
	}

	function burn(
		address account,
		uint256 id,
		uint256 value
	) public virtual {
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);

		_burn(account, id, value);
	}

	/**
	 * READ FUNCTIONS
	 */
	function uri(uint256 tokenID) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, tokenID.toString(), ".json"));
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
	function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
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

	//recover lost nfts. getting them back chance very low
	function reclaimERC1155(
		address erc1155Token,
		uint256 id,
		uint256 amount
	) public onlyOwner {
		IERC1155(erc1155Token).safeTransferFrom(address(this), msg.sender, id, amount, "");
	}

	//change the presale start time. valid for all IDs!
	function setStartTimes(uint256 presale, uint256 publicSale) external onlyOwner {
		presaleStartTime = presale;
		publicStartTime = publicSale;
	}

	//owner reserves the right to change the price
	function setPricePerID(uint256 id, uint256 price) external onlyOwner {
		prices[id] = price;
	}

	//owner reserves the right to change the price
	function setPricePresalePerID(uint256 id, uint256 price) external onlyOwner {
		pricesPresale[id] = price;
	}

	//owner reserves the right to change the price
	function setPricePresaleBulkID(uint256 id, uint256 price) external onlyOwner {
		pricesPresaleBulk[id] = price;
	}

	//owner reserves the right to change the price
	function setMaxSupplyPerID(
		uint256 id,
		uint256 newMaxSupplyPresale,
		uint256 newMaxSupply
	) external onlyOwner {
		if (id == 1) {
			require(newMaxSupply < 1010, "no more than 1010");
			require(newMaxSupplyPresale < 1010, "no more than 1010");
		}
		maxSuppliesPresale[id] = newMaxSupplyPresale;
		maxSupplies[id] = newMaxSupply;
	}

	function setMerkleRoot(bytes32 _root) external onlyOwner {
		root = _root;
	}
}
