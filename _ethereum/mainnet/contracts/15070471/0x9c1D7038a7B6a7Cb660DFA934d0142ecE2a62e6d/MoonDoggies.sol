//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import  "@openzeppelin/contracts/utils/Strings.sol";
import  "@openzeppelin/contracts/utils/Address.sol";
import  "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import  "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import  "@openzeppelin/contracts/utils/Context.sol";
import  "erc721a/contracts/ERC721A.sol";
import  "@openzeppelin/contracts/access/Ownable.sol";

contract MoonDoggies is ERC721A, Ownable {
	using Strings for uint;

	uint public constant mintPrice = 0.0077 ether;
    uint public constant maxPerWallet = 10;
	address private immutable SPLITTER_ADDRESS;
	uint public maxSupply = 7777;

	bool public isPaused = true;
    string private _baseURL = "ipfs://QmUFw3vNfRpJxASUou5zoRPs4aue43nFh2pZej67dwGXDP/";
	mapping(address => uint) private _walletMintedCount;

	constructor(address splitterAddress)
    // Name
	ERC721A('MoonDoggies', 'DOGGIES') {
        SPLITTER_ADDRESS = splitterAddress;
    }

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function setBaseURI(string memory url) external onlyOwner {
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
		require(balance > 0, 'No balance');
		payable(SPLITTER_ADDRESS).transfer(balance);
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
            : _baseURL;
	}

	function mint(uint count) external payable {
		require(!isPaused, 'Sales are off');
		require(_totalMinted() + count <= maxSupply,'Exceeds max supply');
        require(_walletMintedCount[msg.sender] + count <= maxPerWallet,'Exceeds max per wallet');

        uint payForCount = count;
        uint mintedSoFar = _walletMintedCount[msg.sender];
        if(mintedSoFar < 1) {
            uint remainingFreeMints = 1 - mintedSoFar;
            if(count > remainingFreeMints) {
                payForCount = count - remainingFreeMints;
            }
            else {
                payForCount = 0;
            }
        }

		require(
			msg.value >= payForCount * mintPrice,
			'Ether value sent is not sufficient'
		);

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}