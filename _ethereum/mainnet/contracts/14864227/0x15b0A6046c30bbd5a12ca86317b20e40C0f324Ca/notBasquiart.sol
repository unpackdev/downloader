// SPDX-License-Identifier: MIT

// _____________________________________________________________________________
//                         ____                                                 
//                         /   )                            ,                   
// ----__----__--_/_------/__ /-----__---__----__---------------__---)__--_/_---
//   /   ) /   ) /       /    )   /   ) (_ ` /   ) /   /  /   /   ) /   ) /     
// _/___/_(___/_(_ _____/____/___(___(_(__)_(___/_(___(__/___(___(_/_____(_ __o_
//                                             /                                
//                                            (_                                
// 'I don't listen to what art critics say. I don't know anybody who needs a critic to find out what art is.'
//  1111 collection inspired by Jean-Michel Basquiat.


pragma solidity >=0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract notBasquiart is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint;

	uint public price = 0.01 ether;
	uint public maxNFTPerTx = 20;
	uint public totalFreeMint = 555;
	uint public maxSupply = 1111;

	bool public isPaused;
    bool public isMetadataFinal;

    string private _baseURL;
	string public prerevealURL = 'ipfs://QmchzkouGhMvXJwxejNnANKk4ZPY8dz2DxM71S8Ykg1at1';
	mapping(address => uint) private _walletMintedCount;

	constructor() ERC721A('notBasquiart', 'NOTBASQUIART') {}

	function totalMinted() external view returns (uint) {
		return _totalMinted();
	}

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 0;
	}

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "notBasquiart: Metadata is finalized");
		_baseURL = url;
	}

    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

	function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'notBasquiart: Exceeds max supply'
		);
		_safeMint(to, count);
	}

	function setSupply(uint value) external onlyOwner {
		maxSupply = value;
	}

	function adjustFreeMint(uint value) external onlyOwner {
		totalFreeMint = value;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : prerevealURL;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

	function mint(uint count) external payable {
		require(!isPaused, 'notBasquiart: Sales are off');
		require(count <= maxNFTPerTx
,'notBasquiart: Exceeds NFT per transaction limit.');
		require(_totalMinted() + count <= maxSupply,'notBasquiart: Exceeds max supply.');

        uint payForCount = count;
		if(_totalMinted() <= totalFreeMint && _walletMintedCount[msg.sender] == 0) {
            payForCount--;
		}

		require(
			msg.value >= payForCount * price,
			'notBasquiart: Please make at least the minimum donation.'
		); 

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}
