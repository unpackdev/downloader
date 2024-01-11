// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol"; 

contract Minotown is ERC721A, Ownable {

	uint public constant MINT_PRICE = 0.003 ether;
	uint public constant MAX_NFT_PER_TRAN = 5;
    uint public constant MAX_FREE_NFT_PER_TRAN = 2;

	uint public maxSupply = 5555;
	uint public maxFreeSupply = 900;
	uint public maxPerWallet = 20;

	bool public isPaused = true;
    bool public isMetadataFinal;
    string private _baseURL;
	mapping(address => uint) private _walletMintedCount;

	constructor() ERC721A('Minotown', 'MNTWN') {}

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
        require(!isMetadataFinal, "Minotown: Metadata is finalized");
		_baseURL = url;
	}

    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

	function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

	function withdraw(address owner, uint money) external onlyOwner {
		uint balance = money;
		require(balance > 0, 'Minotown: No balance');
		payable(owner).transfer(balance);
	}

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'Minotown: Exceeds max supply'
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
            : "";
	}

	function mint(uint count) external payable {

		require(!isPaused, 'Minotown: Sales are off');
		require(totalSupply() + count <= maxSupply,'Minotown: Exceeds max supply');

        if(totalSupply() + count <= maxFreeSupply) {
		    require(count <= MAX_FREE_NFT_PER_TRAN,'Minotown: Exceeds NFT per transaction limit');
        } else {
            require(count <= MAX_NFT_PER_TRAN,'Minotown: Exceeds NFT per transaction limit');
            require(msg.value >= count * MINT_PRICE, 'Minotown: Ether value sent is not sufficient');
        }

        require(_walletMintedCount[msg.sender] + count <= maxPerWallet, 'Minotown: Exceeds NFT per wallet limit');

       
		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}