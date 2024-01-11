// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract DoodGoblin is ERC721A, Ownable {
	using Strings for uint;

	uint public constant MINT_PRICE = 0.0069 ether;
	uint public constant MAX_NFT_PER_TRAN = 20;
	address private immutable SPLITTER_ADDRESS;
	uint public totalFreeMint = 2500;
	uint public maxSupply = 5000;

	bool public isPaused;
    bool public isMetadataFinal;
    string private _baseURL;
	string public prerevealURL = 'ipfs://QmZakc6GCZBbjvnUMvx9zwafCFngVVTPJSTFyATCSUX8Gb';
	mapping(address => uint) private _walletMintedCount;

	constructor(address splitterAddress)
	ERC721A('DoodGoblin', 'DG') {
        SPLITTER_ADDRESS = splitterAddress;
    }

	function totalMinted() external view returns (uint) {
		return _totalMinted();
	}

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function contractURI() public pure returns (string memory) {
		return "ipfs://QmVfoafSSZgBd9F6GA8L86sVV9gziEZ5YDaP1CmKerMRD9";
	}

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "DoodGoblin: Metadata is finalized");
		_baseURL = url;
	}

    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

	function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

	function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'DoodGoblin: No balance');
		payable(SPLITTER_ADDRESS).transfer(balance);
	}

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'DoodGoblin: Exceeds max supply'
		);
		_safeMint(to, count);
	}

	function setSupply(uint value) external onlyOwner {
		maxSupply = value;
	}

	function adjustFreeMint(uint value) external onlyOwner {
		totalFreeMint = value;
	}

	function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : prerevealURL;
	}

	function mint(uint count) external payable {
		require(!isPaused, 'DoodGoblin: Sales are off');
		require(count <= MAX_NFT_PER_TRAN,'DoodGoblin: Exceeds NFT per transaction limit');
		require(_totalMinted() + count <= maxSupply,'DoodGoblin: Exceeds max supply');

        uint payForCount = count;
		if(_totalMinted() <= totalFreeMint && _walletMintedCount[msg.sender] == 0) {
            payForCount--;
		}

		require(
			msg.value >= payForCount * MINT_PRICE,
			'DoodGoblin: Not enough gold'
		);

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}
