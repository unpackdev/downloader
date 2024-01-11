// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract UglyOnions is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MaxFreePerWallet = 3;
    uint256 public TOTAL_FREE = 555;
    uint256 public price = .001 ether;

    string private  baseTokenUri;

    bool public publicSale;
    bool public teamMinted;


    constructor() ERC721A("UglyOnions", "UGN"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }


    function mint(uint256 amount) external payable {
        require(publicSale, "Minting is not live yet, hold on");
        require(amount <= MAX_PER_TX, "too many");
        require(totalSupply() + amount <= MAX_SUPPLY, "sold out");

        uint256 cost = price;
        if (
            totalSupply() + amount <= TOTAL_FREE &&
            numberMinted(msg.sender) + amount <= MaxFreePerWallet
        ) {
            cost = 0;
        }
        if (
            totalSupply() + amount >= TOTAL_FREE 
           
        ) {
            cost;
        }
        require(msg.value >= amount * cost, "Please send the exact amount.");

        _safeMint(msg.sender, amount);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted,"Team already minted" );
        teamMinted = true;
        _safeMint(msg.sender, 80);
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
    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function withdraw() external onlyOwner{
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
         require(os);
    }
}