// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol"; 

contract DegenPartyGoats is ERC721A, Ownable {

	uint public constant MINT_PRICE = 0.0045 ether;
	uint public constant MAX_NFT_PER_TRAN = 10;

	address private immutable SPLITTER_ADDRESS;
	uint public maxSupply = 5555;

	bool public isPaused = true;
    bool public isMetadataFinal;
    string private _baseURL;
	string public prerevealURL = 'ipfs://QmPjq96LVtj3mGduX3yP1abToyEqZodacfEuezfFYpFct4/hidden.json';
	mapping(address => uint) private _walletMintedCount;

	constructor(address splitterAddress)
	ERC721A('Degen Party Goats', 'DPG') {
        SPLITTER_ADDRESS = splitterAddress;
    }

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "Degen Party Goats: Metadata is finalized");
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
		require(balance > 0, 'Degen Party Goats: No balance');
		payable(SPLITTER_ADDRESS).transfer(balance);
	}

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'Degen Party Goats: Exceeds max supply'
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
            ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"))
            : prerevealURL;
	}

	function mint(uint count) external payable {

		require(!isPaused, 'Degen Party Goats: Sales are off');
		require(totalSupply() + count <= maxSupply,'Degen Party Goats: Exceeds max supply');


		if (_walletMintedCount[msg.sender] == 0) {
			require(msg.value >= (count - 1) * MINT_PRICE, 'Degen Party Goats: Ether value sent is not sufficient');
			require(count <= MAX_NFT_PER_TRAN,'Degen Party Goats: Exceeds NFT per transaction limit');
		} else {
			require(msg.value >= count * MINT_PRICE, 'Degen Party Goats: Ether value sent is not sufficient');
		}



       	_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}