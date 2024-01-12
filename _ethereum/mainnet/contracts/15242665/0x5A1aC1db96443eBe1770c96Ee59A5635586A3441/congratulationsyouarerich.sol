// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract congratulationsyouarerich is ERC721A, Ownable {
    uint256 public maxMintAmountPerTxn = 3;
    uint256 public maxSupply = 300;
    uint256 public mintPrice = 0.1 ether;
    bool public paused = true;
    string public baseURI = "";

    constructor() ERC721A("Congratulations You Are Rich", "CYAR") {}

    function mintTo(address to, uint256 count) external onlyOwner {
		require(_totalMinted() + count <= maxSupply, 'Too much');
		_safeMint(to, count);
	}

    function mint(uint256 count) external payable {
        require(!paused, 'Paused');
        require(count > 0 && count <= maxMintAmountPerTxn, "Invalid mint amount!");
        require(totalSupply() + count <= maxSupply, "Not enough tokens left");
        require(msg.value >= (mintPrice * count), "Not enough ether sent");
        _safeMint(msg.sender, count);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintAmountPerTxn(uint256 _maxMintAmountPerTxn) public onlyOwner {
        maxMintAmountPerTxn = _maxMintAmountPerTxn;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }
}