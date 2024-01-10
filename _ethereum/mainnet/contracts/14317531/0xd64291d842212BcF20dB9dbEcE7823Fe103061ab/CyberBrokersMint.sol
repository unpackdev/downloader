// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./CyberBrokers.sol";

contract CyberBrokersMint is ReentrancyGuard, Ownable
{
	// CyberBrokers token contract
	CyberBrokers public cyberBrokers;

	// CONSTANTS
	uint256 public constant MINT_PRICE = 0.35 ether;

	// Sale Allowlist
	bytes32 public saleMerkleRoot;
	mapping(address => uint) public saleAllowlistClaimed;

	// Claim Allowlist
	bytes32 public claimMerkleRoot;
	mapping(address => uint) public claimAllowlistClaimed;

	// Random mint variables
	uint256 internal _leftToMint;
	uint256 internal _leftToPurchase;
	uint256 internal _leftToClaim;
	mapping(uint256 => uint256) internal _idSwaps;
	uint256 internal _currentPrng;
	uint256 public constant RESERVED_FOR_CLAIM = 309;

	// Sale switches
	bool internal _saleStarted = false;
	bool internal _openWaitList = false;
	bool internal _openSale = false;

	constructor(
		address _CyberBrokersAddress,
		bytes32 _saleMerkleRoot,
		bytes32 _claimMerkleRoot
	) {
		// Set the token address
		cyberBrokers = CyberBrokers(_CyberBrokersAddress);

		// Set the remaining to mint, as well as purchase and claim mints remaining
		_leftToMint     = cyberBrokers.TOTAL_CYBERBROKERS() - cyberBrokers.totalMinted();
		_leftToPurchase = _leftToMint - RESERVED_FOR_CLAIM;
		_leftToClaim    = RESERVED_FOR_CLAIM;

		// Set the allowlist merkleRoots - sales and free claims
		setSaleMerkleRoot(_saleMerkleRoot);
		setClaimMerkleRoot(_claimMerkleRoot);
	}

	function _mintCyberBrokers(
		address _to,
		uint256 _numTokens
	)
		private
	{
		// Validate that number of tokens is greater than zero
		require(_numTokens > 0, "Must mint 1 or more tokens");

		// Sanity check -- validate that we don't mint more than the total
		require(_numTokens <= _leftToMint, "Mint request exceeds supply");

		// Copy the current data
		uint256 leftToMint = _leftToMint;
		uint256 currentPrng = _currentPrng;

		// Mint tokens in random
		uint256 _tokenId;
		for (uint256 i = 0; i < _numTokens; i++) {
			// Generate the next random number
			currentPrng = _prng(currentPrng, leftToMint);

			// Pull the next token ID
			_tokenId = _pullRandomTokenId(currentPrng, leftToMint);

			// Decrement the local mint counter
			leftToMint--;

			// Mint the token
			cyberBrokers.mintCyberBrokerFromMintContract(_to, _tokenId);
		}

		// Store the latest values
		_currentPrng = currentPrng;
		_leftToMint = leftToMint;
	}

	function setSaleStarted(bool _setting) public onlyOwner {
		_saleStarted = _setting;
	}

	function isSaleStarted() public view returns (bool) {
		return _saleStarted;
	}

	function setOpenWaitList(bool _setting) public onlyOwner {
		_openWaitList = _setting;
	}

	function setOpenSale(bool _setting) public onlyOwner {
		_openSale = _setting;
	}

	function isOpenWaitList() public view returns (bool) {
		return _openWaitList;
	}

	function isOpenSaleToAllowlist() public view returns (bool) {
		return _openSale;
	}

	function purchase(
		bytes32[] calldata _proof,
		uint256 _allowedAmount,
		bool _onWaitlist,
		uint256 _numTokens
	)
		external
		payable
		nonReentrant
	{
		// Require that the sale has started
		require(_saleStarted, "Sale has not started");

		// Check that purchase is legal per allowlist
		require(reviewSaleProof(msg.sender, _proof, _allowedAmount, _onWaitlist), "Proof does not match data");
		require(
			(saleAllowlistClaimed[msg.sender] + _numTokens) <= (_allowedAmount + (_openWaitList && _onWaitlist ? 1 : 0)) || // Allowed amount limit
			(_openSale && _numTokens <= 3) // In an open sale, all approved addresses can mint three per transaction
		, "Can not exceed permitted amount");

		// Validate ETH sent
		require((MINT_PRICE * _numTokens) == msg.value, "Incorrect ETH value sent");

		// Check that there are mints available for purchase
		require(_numTokens <= _leftToPurchase, "Mint request exceeds purchase supply");
		_leftToPurchase -= _numTokens;

		// Update allowlist claimed
		saleAllowlistClaimed[msg.sender] = saleAllowlistClaimed[msg.sender] + _numTokens;

		// Continue with the mint
		_mintCyberBrokers(msg.sender, _numTokens);
	}

	function claim(
		bytes32[] calldata _proof,
		uint256 _allowedAmount,
		uint256 _numTokens
	)
		external
		nonReentrant
	{
		// Require that the sale has started
		require(_saleStarted, "Sale has not started");

		// Check that purchase is legal per allowlist
		require(reviewClaimProof(msg.sender, _proof, _allowedAmount, false), "Proof does not match data");
		require((claimAllowlistClaimed[msg.sender] + _numTokens) <= _allowedAmount, "Can not exceed permitted amount");

		// Check that there are mints available for claim
		require(_numTokens <= _leftToClaim, "Mint request exceeds claim supply");
		_leftToClaim -= _numTokens;

		// Update allowlist claimed
		claimAllowlistClaimed[msg.sender] = claimAllowlistClaimed[msg.sender] + _numTokens;

		// Continue with the mint
		_mintCyberBrokers(msg.sender, _numTokens);
	}

	function countRemainingMints() public view returns (uint256) {
		return _leftToMint;
	}

	function countRemainingPurchase() public view returns (uint256) {
		return _leftToPurchase;
	}

	function countRemainingClaims() public view returns (uint256) {
		return _leftToClaim;
	}

	/**
	 * Withdraw functions
	 **/
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		(bool success,) = msg.sender.call{value: balance}('');
		require(success, 'Fail Transfer');
	}

	/**
	 * Allowlist Merkle Data
	 * Credit for Merkle setup code: Cobble
	 **/
	function getLeaf(address addr, uint256 amount, bool waitlist) public pure returns(bytes32) {
		return keccak256(abi.encodePacked(addr, amount, waitlist));
	}

	function reviewSaleProof(
		address _sender,
		bytes32[] calldata _proof,
		uint256 _allowedAmount,
		bool _onWaitlist
	) public view returns (bool) {
		return MerkleProof.verify(_proof, saleMerkleRoot, getLeaf(_sender, _allowedAmount, _onWaitlist));
	}

	function reviewClaimProof(
		address _sender,
		bytes32[] calldata _proof,
		uint256 _allowedAmount,
		bool _onWaitlist
	) public view returns (bool) {
		return MerkleProof.verify(_proof, claimMerkleRoot, getLeaf(_sender, _allowedAmount, _onWaitlist));
	}

	function setSaleMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
		saleMerkleRoot = _merkleRoot;
	}

	function setClaimMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
		claimMerkleRoot = _merkleRoot;
	}

	/**
	 * Credit: created by dievardump (Simon Fremaux)
	 **/
	function _pullRandomTokenId(
		uint256 currentPrng,
		uint256 leftToMint
	)
		internal
		returns (uint256)
	{
		require(_leftToMint > 0, "No more to mint");

		// get a random id
		uint256 index = 1 + (currentPrng % leftToMint);
		uint256 tokenId = _idSwaps[index];
		if (tokenId == 0) {
			tokenId = index;
		}

		uint256 temp = _idSwaps[leftToMint];

		// "swap" indexes so we don't loose any unminted ids
		// either it's id _leftToMint or the id that was swapped with it
		if (temp == 0) {
			_idSwaps[index] = leftToMint;
		} else {
			// get some refund
			_idSwaps[index] = temp;
			delete _idSwaps[leftToMint];
		}

		return tokenId;
	}

	function _prng(
		uint256 currentPrng,
		uint256 leftToMint
	)
		internal
		view
		returns (uint256)
	{
		return uint256(
			keccak256(
				abi.encodePacked(
					blockhash(block.number - 1),
					currentPrng,
					leftToMint
				)
			)
		);
	}

}
