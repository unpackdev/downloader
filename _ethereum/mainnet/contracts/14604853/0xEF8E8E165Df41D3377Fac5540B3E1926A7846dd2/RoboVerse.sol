// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract RoboVerse is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1150;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant MAX_PER_TX = 5;
    uint256 public price = .0005 ether;

    string private  baseTokenUri;

    bool public isRevealed;
    bool public publicSale;
    bool public teamMinted;


    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("RoboVerse", "RVN"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "RoboVerse :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "RoboVerse :: Not Yet Active.");
        require(_quantity > 0 && _quantity <= MAX_PER_TX, "ERROR: Max per transaction exceeded");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "RoboVerse :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "RoboVerse :: Already minted 10 times!");
        require(msg.value >= (price * _quantity), "RoboVerse :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    function teamMint() external onlyOwner{
        require(!teamMinted, "RoboVerse :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 50);
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;
        
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }
    
    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    
	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function withdraw() external onlyOwner{
       (bool os, ) = payable(owner()).call{value: address(this).balance}("");
         require(os);
    }
}