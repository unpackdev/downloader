// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GroovyGoblins is ERC721A, Ownable {

    uint256 public pricePerNFT = 0.005 ether;
    uint256 public max_per_tx = 10;

    uint256 public maxSupply = 4444;
    uint256 public totalFreeMints = 999; // Actually 1000, contract checks this

    bool public getGroovy = false;
    bool public isMetadataFinal = false;

    string public _baseURL;

    constructor() ERC721A("Groovy Goblins", "GG") { 
        // _currentIndex = _startTokenId(); // Start index from #1
    }

    function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

    function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function mintGroovyGoblins(uint256 _amount) 
        external 
        payable 
    {
        uint256 mintPrice = pricePerNFT;
        require(msg.sender == tx.origin, "Caller is an external contract.");
        require(getGroovy, "Sale is not live yet.");
        require(totalSupply() + _amount <= maxSupply, "All goblins have been minted.");
        require(_numberMinted(msg.sender) + _amount <= max_per_tx, "Too many mints for this wallet.");
        if (totalSupply() > totalFreeMints) {
            require(msg.value == _amount * mintPrice, "Incorrect amount of ETH send.");
        }

        // Get your Goblins
        _safeMint(msg.sender, _amount);
    }

    function airdropNFT(address _mintToAddress, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Maximum supply exceeded.");
        _safeMint(_mintToAddress, _amount);
    }

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

    // Setting sale state
    function setGetGroovy(bool _getGroovy) external onlyOwner {
        getGroovy = _getGroovy;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!isMetadataFinal, "Metadata is locked.");
        _baseURL = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        pricePerNFT = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Balance withdraw failed, please try again.");
    }
}
