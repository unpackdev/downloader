// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TinyMoonBirds is ERC721A, Ownable {
    using Strings for uint256;
    
    uint256 public MAX_SUPPLY = 4444;
    uint256 public price = 0.0025 ether;
    
    bool isRevealed = false;
    bool public saleOpen = false;
    
    mapping(address => uint256) public addressMintCount;

    string private baseTokenURI;

    constructor() ERC721A("Tiny MoonBirds", "TMB") {}

    event Minted(uint256 totalMinted);

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _count) external payable {
        uint256 supply = totalSupply();
        require(saleOpen,  "Sale is not open yet");
        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum supply");
        require(addressMintCount[msg.sender] + _count < 11, "Exceeds max per wallet");
        if(supply > 1000 && msg.sender != owner())
        {
            require(msg.value == price * _count, "Ether sent with this transaction is not correct");
        }
        
        addressMintCount[msg.sender] += _count;
        _safeMint(msg.sender, _count);
        emit Minted(_count);       
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return isRevealed ? string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json")) : _baseURI();
    }

    function flipSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function flipReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function revealCollection(bool _revealed, string memory _baseUri) public onlyOwner {
        isRevealed = _revealed;
        baseTokenURI = _baseUri;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}