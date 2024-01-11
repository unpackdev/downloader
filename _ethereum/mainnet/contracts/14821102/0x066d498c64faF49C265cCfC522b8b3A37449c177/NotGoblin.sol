// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract NotGoblin is ERC721A, Ownable {
	using Strings for uint;

	uint public constant MINT_PRICE = 0.0069 ether;
	uint public constant MAX_NFT_PER_TRAN = 20;
	address private immutable SPLITTER_ADDRESS;
	uint public maxSupply = 9999;

	bool public isPaused;
    bool public isMetadataFinal;
    string private _baseURL;
	string public prerevealURL = 'ipfs://QmRqDKDc3vuzrq8V15mg4gnxWAC6uZpQJJfberV3Xnrv1w';
	mapping(address => uint) private _walletMintedCount;

	constructor(address splitterAddress)
	ERC721A('NotGoblin', 'NGWTF') {
        SPLITTER_ADDRESS = splitterAddress;
    }

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function contractURI() public pure returns (string memory) {
		return "ipfs://QmZPPFr4Q1X6Wk2zHkNTKuz9gfGgk1cj81i88NjMMe57P8";
	}

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "Not Goblin: Metadata is finalized");
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
		require(balance > 0, 'Not Goblin: No balance');
		payable(SPLITTER_ADDRESS).transfer(balance);
	}

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'Not Goblin: Exceeds max supply'
		);
		_safeMint(to, count);
	}

	function reduceSupply(uint newMaxSupply) external onlyOwner {
		maxSupply = newMaxSupply;
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
		require(!isPaused, 'NotGoblin: Sales are off');
		require(count <= MAX_NFT_PER_TRAN,'NotGoblin: Exceeds NFT per transaction limit');
		require(_totalMinted() + count <= maxSupply,'NotGoblin: Exceeds max supply');

        uint payForCount = count;
        if(_walletMintedCount[msg.sender] == 0) {
            payForCount--;
        }

		require(
			msg.value >= payForCount * MINT_PRICE,
			'NotGoblin: Ether value sent is not sufficient'
		);

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}
