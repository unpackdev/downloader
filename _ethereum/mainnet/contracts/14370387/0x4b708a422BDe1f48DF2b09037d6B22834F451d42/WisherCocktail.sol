// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract WisherCocktail is ERC721Enumerable, Ownable {

	using Strings for uint256;
	using MerkleProof for bytes32[];

	// Constants
	uint public MAX_SUPPLY;
	string public PROVENANCE_HASH;

	// Global sale state
	bool public isSaleEnabled = true;

	// Pre/Post Reveal Metadata URIs
	string public baseURI;
	string public preRevealURI = "ipfs://QmTv5iyHGiFh2cXv64RAfbBPHsxcYpMFfoViZKZspKLmQ1";

	// Pre-sale State
	bytes32 public preSaleRoot = 0x6b965640fb01564915f3ea1218b5310ea0b2b48691db44f07851877d4f836a35;
	uint256 public preSaleStart = 1647105060;
	uint256 public preSalePrice = 0.2 ether;

	// Sale State 
	uint256 public publicSaleStart = 1647148260;
	uint256 public publicSalePrice = 0.29 ether;

	// Randomized Start Index
	uint256 public startIndex;
	uint256 public startIndexBlock;

	constructor(
		string memory name,
		string memory symbol,
		string memory provenanceHash,
		uint256 maxSupply
	) ERC721(name, symbol) {
		MAX_SUPPLY = maxSupply;
		PROVENANCE_HASH = provenanceHash;
	}

	modifier saleEnabled {
		require(isSaleEnabled, "Minting is currently disabled");
		_;
	}

	modifier hasFunds(uint256 quantity, uint256 fee) {
		require(fee * quantity <= msg.value, "Insufficient ETH to complete mint");
		_;
	}

	modifier whitelist(bytes32[] memory proof) {
		require(
			proof.verify(preSaleRoot, keccak256(abi.encodePacked(msg.sender))),
			"This address does not have access to pre-sale minting"
		);	
	 	_;
	}

	/// Replace the current baseURI with a new value
	/// @dev only here in the event the metadata/image host needs to be replaced
	function setBaseURI(string memory uri) public onlyOwner {
		baseURI = uri;
	}

	/// Set the pre-sale URI
	/// @dev this URI will be used in place of all token URIs until the final metadata is revealed
	function setPreRevealURI(string memory uri) public onlyOwner {
		preRevealURI = uri;
	}

	/// Set the merkle root used to identify whitelisted pre-sale addresses
	function setPreSaleRoot(bytes32 root) public onlyOwner {
		preSaleRoot = root;
	}

	/// Set the start timestamp for the pre-sale period
	function setPreSaleStart(uint256 start) public onlyOwner {
		preSaleStart = start;
	}

	/// Set the mint price for the pre-sale period
	function setPreSalePrice(uint256 price) public onlyOwner {
		preSalePrice = price;
	}

	/// Kick off the sale
	function setPublicSaleStart(uint256 start) public onlyOwner {
		publicSaleStart = start;
	}

	/// Kick off the sale
	function setPublicSalePrice(uint256 price) public onlyOwner {
		publicSalePrice = price;
	}

	/// Set the global sale state
	function setSaleIsEnabled(bool enabled) public onlyOwner {
		isSaleEnabled = enabled;
	}

	/// Uses the startIndexBlock to determine the startIndex
	/// @dev startIndexBlock must be set either automatically once the max supply has been
	/// met or manually if you want to reveal the metadata prior to that
	function setStartIndex() public onlyOwner {
		require(startIndex == 0, "Start index has already been set");
		require(startIndexBlock != 0, "Start index block has not been set");

		startIndex = uint(blockhash(startIndexBlock)) % MAX_SUPPLY;
		if ((block.number - startIndexBlock) > 255) {
			startIndex = uint(blockhash(block.number - 1)) % MAX_SUPPLY;
		}

		if (startIndex == 0) {
			startIndex = 1;
		}
	}

	/// Manually set the startIndexBlock
	/// @dev this shouldn't be used unless the seller decides to reveal prior to selling the max supply
	function setStartIndexBlock() public onlyOwner {
		require(startIndex == 0, "Start index has already been set");
		startIndexBlock = block.number;
	}

	/// Override the default implementation to return our base URI
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	/// Override the default implementation to return our pre-reveal URI until the final metadata is revealed
	/// @dev to reveal the set just provide a baseURI
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "URI query for nonexistent token");
		return bytes(baseURI).length > 0
			? string(abi.encodePacked(baseURI, tokenId.toString()))	
			: preRevealURI;
	}

	/// Mint one or more NFTs to the sender if the supply and provided ETH allow
	/// @dev also sets the startIndexBlock if this is the max supply has been minted
	function purchasePreSale(address to, uint256 quantity, bytes32[] memory proof) public payable saleEnabled whitelist(proof) hasFunds(quantity, preSalePrice) {
		require(!isPrimarySaleActive(), "The pre-sale period has ended");
		require(isPreSaleActive(), "The pre-sale period has not started yet");
		mint(to, quantity);
	}

	/// Mint one or more NFTs to the sender if the supply and provided ETH allow
	function purchase(address to, uint256 quantity) public payable saleEnabled hasFunds(quantity, publicSalePrice) {
		require(isPrimarySaleActive(), "Sale is not active yet");
		mint(to, quantity);
	}

	/// Allow the contract owner to reserve 'quantity' NFTs
	function reserve(uint256 quantity) public onlyOwner {
		mint(msg.sender, quantity);
	}

	/// Withdraw the funds held by the contract
	function withdraw() public payable onlyOwner {
        uint amount = address(this).balance;
		(bool success, ) = msg.sender.call{ value: amount }("");
		require(success, "Withdrawal request failed");
	}

	// Private Methods

	function isPreSaleActive() private view returns (bool) {
		return preSaleStart > 0 && block.timestamp >= preSaleStart;
	}

	function isPrimarySaleActive() private view returns (bool) {
		return block.timestamp >= publicSaleStart;
	}

	// Mint the token(s) to the provided address
	/// @dev this also sets the startIndexBlock if the max supply has been minted
	function mint(address to, uint256 quantity) private {
		uint256 supply = totalSupply();
		require(quantity > 0, "Mint quantity must be greater than zero");
		require(supply + quantity <= MAX_SUPPLY, "Mint request would exceed maximum supply");

		for (uint256 i = 0; i < quantity; i++) {
			_safeMint(to, supply + i);
		}

		if (startIndexBlock == 0 && (totalSupply() == MAX_SUPPLY)) {
			startIndexBlock = block.number;
		}
	}

}