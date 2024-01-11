//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/*
  ____            _             _               _    _ 
 |  _ \ _   _ ___| |_ ___      / \    _____   _| | _(_)
 | | | | | | / __| __/ _ \    / _ \  |_  / | | | |/ / |
 | |_| | |_| \__ \ || (_) |  / ___ \  / /| |_| |   <| |
 |____/ \__, |___/\__\___/  /_/   \_\/___|\__,_|_|\_\_|
        |___/
*/

error NotEnoughFunds();
error ExceedsSupply();
error ExceedsTransactionLimit();
error InvalidClaim();
error MintNotStarted();
error WhitelistFinished();
error EmptyBalance();
error WithdrawFailed();

contract DystoAzuki is ERC721A, Ownable {
	using Strings for uint256;

	bytes32 public WHITELIST_MERKLE_ROOT;

	address[5] private contributorAddresses;
	mapping(address => uint256) private contributorShares;

	uint256 public freeMints;
	uint256 public constant TOTAL_MAX_SUPPLY = 3300;
	uint256 public constant FREE_MINTS = 300;
	uint256 public constant MAX_PER_TX_WL = 5;
	uint256 public constant MAX_PER_TX_PUBLIC = 15;
	uint256 public constant PRICE_PER_MINT = 0.019 ether;

	bool public mintStarted;
	uint256 public publicMintStartTime;

	bool public revealed;
	string public baseURI="ipfs://QmTCAWhQaKau4d8NuLhN4aaSfRbr7kGhbJhdhbmRb9EYLr";

	constructor(address[5] memory _contributorAddresses) ERC721A("DystoAzuki", "DYSZUKI") {

		contributorAddresses[0] = _contributorAddresses[0];
		contributorAddresses[1] = _contributorAddresses[1];
		contributorAddresses[2] = _contributorAddresses[2];
		contributorAddresses[3] = _contributorAddresses[3];
		contributorAddresses[4] = _contributorAddresses[4];
		
		contributorShares[contributorAddresses[0]] = 3000;
		contributorShares[contributorAddresses[1]] = 2500;
		contributorShares[contributorAddresses[2]] = 2500;
		contributorShares[contributorAddresses[3]] = 1250;
		contributorShares[contributorAddresses[4]] = 750;
	}

	function startMint() external onlyOwner {
		mintStarted = true;
		publicMintStartTime = block.timestamp + 900;
	}

	function stopMint() external onlyOwner {
		mintStarted = false;
	}

	function startPublicMint() external onlyOwner {
		publicMintStartTime = block.timestamp;
	}

	function withdraw() external {
		if (address(this).balance == 0) revert EmptyBalance();
		uint256 balance = address(this).balance;
		for (uint256 i=0; i< contributorAddresses.length; i++) {
			(bool sent, ) = contributorAddresses[i].call{value: balance * contributorShares[contributorAddresses[i]] /10000}("");
			if(!sent) revert WithdrawFailed();
		}
	}

	function setWhitelistRoot(bytes32 _root) external onlyOwner {
		WHITELIST_MERKLE_ROOT = _root;
	}

	function setBaseURI(string calldata _newBaseURI) external onlyOwner {
		baseURI = _newBaseURI;
		revealed = true;
	}

	function _baseURI() internal view override returns (string memory){
		return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		  if(!revealed) {
			return baseURI;
		  }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

	function _startTokenId() internal view override returns (uint256) {
		return 1;
	}

	function airdrop(address _to, uint256 _quantity) external onlyOwner {
		if(totalSupply() + _quantity > TOTAL_MAX_SUPPLY) revert ExceedsSupply();
		_safeMint(_to, _quantity);
	}

	function whitelistMint(uint256 _quantity, bytes32[] calldata _proof) external payable {
		if(!mintStarted) revert MintNotStarted();
		if(block.timestamp > publicMintStartTime) revert WhitelistFinished();
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		(bool success, ) = MerkleProof.verify(_proof, WHITELIST_MERKLE_ROOT, leaf);
		if(!success) revert InvalidClaim();
		
		if(totalSupply() + _quantity > TOTAL_MAX_SUPPLY) revert ExceedsSupply();
		if(_quantity > MAX_PER_TX_WL) revert ExceedsTransactionLimit();

		if (freeMints < FREE_MINTS) {
			_safeMint(msg.sender, _quantity);
			unchecked {
				freeMints += _quantity;
			}
		} else {
			if (msg.value < PRICE_PER_MINT * _quantity) revert NotEnoughFunds();
			_safeMint(msg.sender, _quantity);
		}

	}

	function mint(uint256 _quantity) external payable {
		if(!mintStarted) revert MintNotStarted();
		if(block.timestamp < publicMintStartTime) revert MintNotStarted();
		if(totalSupply() + _quantity > TOTAL_MAX_SUPPLY) revert ExceedsSupply();
		if(_quantity > MAX_PER_TX_PUBLIC) revert ExceedsTransactionLimit();

		if (freeMints < FREE_MINTS) {
			_safeMint(msg.sender, _quantity);
			unchecked {
				freeMints += _quantity;
			}
		} else {
			if (msg.value < PRICE_PER_MINT * _quantity) revert NotEnoughFunds();
			_safeMint(msg.sender, _quantity);
		}
	}

	receive() payable external {}
}