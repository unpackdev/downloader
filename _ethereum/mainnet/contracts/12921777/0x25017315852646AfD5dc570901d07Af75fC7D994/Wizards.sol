// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./IERC20.sol";

/**
 * @title Wizards contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Wizards is ERC721, ERC721Enumerable, Ownable {
	using SafeMath for uint256;
	using Strings for string;

	string public WIZARDS_PROVENANCE = "";

	uint256 public constant wizardPrice = 50000000000000000; // 0.05 ETH

	uint8 public constant maxWizardPurchase = 20;

	uint256 public constant MAX_WIZARDS = 7777;

	string public _baseTokenURI = "https://wizardfest.io/metadata/";

	string public _contractURI = "https://wizardfest.io/contract.json";

	bool public saleIsActive = false;

	bool public initialReserved = false;

	bool public provenanceLocked = false;

	bool public baseTokenURILocked = false;

	bool public trackingHoldTime = true;

	bool public trackingHoldTimeLocked = false;

	uint[] acquiredAt;


	constructor() ERC721("The Wizard's Festival", "WIZARD") {}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}
	
	function setBaseURI(string memory baseURI) public onlyOwner {
		require(!baseTokenURILocked, "baseTokenURI is permanently locked.");
		_baseTokenURI = baseURI;
	}

	function lockBaseURI() public onlyOwner {
		baseTokenURILocked = true;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	// Set provenance once it's calculated
	function setProvenanceHash(string memory provenanceHash) public onlyOwner {
		require(!provenanceLocked, "Provenance hash is permanently locked.");
		WIZARDS_PROVENANCE = provenanceHash;
	}

	// Prevent future changes to provenance hash
	function lockProvenanceHash() public onlyOwner {
		provenanceLocked = true;
	}

	// In case any issue arises with tracking hold time impacting transferability
	function toggleTrackingHoldTime() public onlyOwner {
		require(!trackingHoldTimeLocked, "Tracking hold time is permanently locked.");
		if (trackingHoldTime) {
			trackingHoldTime = false;
		}
		else {
			trackingHoldTime = true;
		}
	}

	// Make the status of tracking hold time permanent
	function lockTrackingHoldTime() public onlyOwner {
		trackingHoldTimeLocked = true;
	}

	function _burn(uint256 tokenId) internal override(ERC721) {
		super._burn(tokenId);
	}

	/* Pause sale if active, make active if paused */
	function flipSaleState() public onlyOwner {
		saleIsActive = !saleIsActive;
	}

	/* Set a maximum of 77 wizards aside for airdrop to the 50 GEN1 Willow owners, and giveaways */
	function reserveWizards() public onlyOwner {
		require(!initialReserved, 'Initial wizards already reserved');

		uint supply = totalSupply();
		uint i;
		for (i = 0; i < 20; i++) {
			_safeMint(msg.sender, supply + i);
			if (supply + i >= 76) {
				initialReserved = true;
				return;
			}
		}
	}

	/* Mint Wizards */
	function mintWizard(uint numberOfTokens) public payable {
		require(saleIsActive, "Sale must be active to mint Wizard");
		require(numberOfTokens <= maxWizardPurchase, "Can only mint 20 tokens at a time");
		require(numberOfTokens > 0, "Can't mint less than 1");
		require(totalSupply().add(numberOfTokens) <= MAX_WIZARDS, "Purchase would exceed max supply of Wizards");
		require(wizardPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
		
		for(uint i = 0; i < numberOfTokens; i++) {
			uint mintIndex = totalSupply();
			if (mintIndex < MAX_WIZARDS) {
				_safeMint(msg.sender, mintIndex);
			}
		}
	}

	function exists(uint256 _tokenId) public view returns (bool) {
		return _exists(_tokenId);
	}

	function tokensInWallet(address _owner) external view returns(uint256[] memory) {
		uint tokenCount = balanceOf(_owner);

		uint256[] memory tokensId = new uint256[](tokenCount);
		for(uint i = 0; i < tokenCount; i++){
			tokensId[i] = tokenOfOwnerByIndex(_owner, i);
		}

		return tokensId;
	}
	
	// Track how long an address has held a specific wizard
	function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(_from, _to, _tokenId);
		if (_from != _to && trackingHoldTime) {
			uint256 startBlock = block.number;

			if (_tokenId >= totalSupply() - 1) {
				acquiredAt.push(startBlock);
			}
			else {
				acquiredAt[_tokenId] = startBlock;
			}
		}
	}

	// Returns how long the same address has held a specific wizard
	function holdDuration(uint256 _tokenId) public view returns (uint) {
		require(_exists(_tokenId), "Token has not been minted.");
		return block.number - acquiredAt[_tokenId];
	}

	// Returns the block number when a wizard was acquired by the current owner
	function holdStartBlock(uint256 _tokenId) public view returns (uint) {
		require(_exists(_tokenId), "Token has not been minted.");
		return acquiredAt[_tokenId];
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}
