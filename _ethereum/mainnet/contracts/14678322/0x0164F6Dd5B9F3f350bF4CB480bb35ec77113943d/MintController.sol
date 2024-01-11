// SPDX-License-Identifier: MIT
// Creator: leb0wski.eth

pragma solidity ^0.8.1;

import "./Brand.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract MintController is Ownable {

	Brand private _token;
	// minting management
	bool public mintEnabled;
	bool public whitelistMintEnabled;
	uint256 public mintPrice = 0.25 ether;
	uint256 public whitelistMintPrice = 0.15 ether;
	uint256 public whitelistDiscountedPrice = 0.4 ether;
	uint256 public discountThreshold = 3;
	uint256 public mintsPerWhitelistSpot = 3;

	// payout vaults
	enum Vault {
		CREATORS,
		BRAND,
		CHARITY
	}
	mapping (Vault => address) public vaults;

	// Whitelist Merkle Proof
	bytes32 whitelistMerkleRoot = 0x36ec4e02398bb495259b5d7a94b4e851f9bce204acd36424a492e61aed13e491;
	mapping (address => uint256) public whitelistClaimed;

	// Giveaway Merkle Proof
	bytes32 giveawayMerkleRoot = 0x36ec4e02398bb495259b5d7a94b4e851f9bce204acd36424a492e61aed13e491;
	mapping (address => bool) public giveawayClaimed;

	// custom sells to partners
	mapping (address => uint256) public partnersThresholds;
	mapping (address => uint256) public partnersPrices;

	constructor(address collection_, address creatorsVault_, address brandVault_, address charityVault_) {
		vaults[Vault.CREATORS] = creatorsVault_;
		vaults[Vault.BRAND] = brandVault_;
		vaults[Vault.CHARITY] = charityVault_;
		_token = Brand(collection_);
	}

	function publicMint(uint256 amount_) public payable returns(bool) {
		require(amount_ > 0, "You should mint at least one token.");
		require(amount_ < 5, "You can mint a max of 5 tokens per transaction.");
		require(msg.value >= mintPrice * amount_, "Please check amount sent for mint.");
		require(mintEnabled, "Public mint is closed.");
		
		_token.mint(msg.sender, amount_);

		payout(msg.value);

		return true;
	}

	function whitelistMint(bytes32[] calldata merkleProof_, uint256 amount_) public payable returns(bool) {
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		require(MerkleProof.verify(merkleProof_, whitelistMerkleRoot, leaf), "You are not in whitelist.");
		require((whitelistClaimed[msg.sender] + amount_) <= mintsPerWhitelistSpot, "You already minted your NFTs.");
		require(whitelistMintEnabled == true, "Whitelist Mint is closed.");

		if(amount_ == discountThreshold) {
			require(msg.value >= whitelistDiscountedPrice, "Please check amount sent for whitelist mint.");
		} else {
			require(msg.value >= whitelistMintPrice * amount_, "Please check amount sent for whitelist mint.");
		}
		
		_token.mint(msg.sender, amount_);
		whitelistClaimed[msg.sender] += amount_;

		payout(msg.value);

		return true;
	}

	function giveawayMint(bytes32[] calldata merkleProof_) public returns(bool) {
		require(whitelistMintEnabled == true, "Whitelist Mint is closed.");

		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		require(MerkleProof.verify(merkleProof_, giveawayMerkleRoot, leaf), "You are not in whitelist.");
		require(!giveawayClaimed[msg.sender], "You already minted your Free NFT.");

		_token.mint(msg.sender, 1);
		giveawayClaimed[msg.sender] = true;

		return true;
	}

	function partnerMint(uint256 amount_) public payable returns(bool) {
		require(whitelistMintEnabled == true, "Whitelist Mint is closed.");
		require((partnersThresholds[msg.sender] - amount_) >= 0, "You already minted your NFTs.");
		require(msg.value >= (partnersPrices[msg.sender] * amount_), "Please check amount sent for mint.");

		_token.mint(msg.sender, amount_);
		partnersThresholds[msg.sender] -= amount_;

		payout(msg.value);

		return true;
	}

	function reveal(string memory uri_) public onlyOwner {
		_token.reveal(uri_);
	}

	function toggleMint() public onlyOwner {
		mintEnabled = !mintEnabled;
	}

	function toggleWhitelistMint() public onlyOwner {
		whitelistMintEnabled = !whitelistMintEnabled;
	}

	function setMintPrice(uint256 price_) public onlyOwner {
		mintPrice = price_;
	}

	function setWhitelistMintPrice(uint256 price_) public onlyOwner {
		whitelistMintPrice = price_;
	}

	function setMerkleTreeRoot(bytes32 merkleRoot_) public onlyOwner {
		whitelistMerkleRoot = merkleRoot_;
	}

	function setGiveawayMerkleTreeRoot(bytes32 merkleRoot_) public onlyOwner {
		giveawayMerkleRoot = merkleRoot_;
	}

	function setMintsPerWhitelistSpot(uint256 mints_) public onlyOwner {
		mintsPerWhitelistSpot = mints_;
	}

	function setDiscountedPrice(uint256 price_) public onlyOwner {
		whitelistDiscountedPrice = price_;
	}

	function isInWhitelist(bytes32[] calldata merkleProof_) public view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		return MerkleProof.verify(merkleProof_, whitelistMerkleRoot, leaf);
	}

	function setPartnerThreshold(address partner_, uint256 threshold_) public onlyOwner {
		partnersThresholds[partner_] = threshold_;
	}

	function setPartnerPrice(address partner_, uint256 price_) public onlyOwner {
		partnersPrices[partner_] = price_;
	}

	function setVault(Vault vault_, address address_) public onlyOwner {
		vaults[vault_] = address_;
	}

	function payout(uint256 amount_) internal {
		payable(vaults[Vault.CREATORS]).transfer(amount_ / 100 * 40);
		payable(vaults[Vault.BRAND]).transfer(amount_ / 100 * 40);
		payable(vaults[Vault.CHARITY]).transfer(amount_ / 100 * 20);
	}
}
