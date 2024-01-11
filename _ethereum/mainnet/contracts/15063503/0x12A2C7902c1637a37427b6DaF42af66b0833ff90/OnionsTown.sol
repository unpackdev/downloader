// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OnionsTown is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public price = .002 ether;

    mapping(address => bool) public freeMinted;


    string private  baseTokenUri;

    bool public publicSale;
    bool public teamMinted;


    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("OnionsTown", "OTN"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "OnionsTown :: Cannot be called by a contract");
        _;
    }

    function mintMore(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "OnionsTown :: Not Yet Active.");
        require(_quantity > 0 && _quantity <= MAX_PER_TX, "ERROR: Max per transaction exceeded");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "OnionsTown :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "OnionsTown :: Already minted 10 times!");
        require(msg.value >= (price * _quantity), "OnionsTown :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    function teamMint() external onlyOwner{
        require(!teamMinted, "OnionsTown :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 157);
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function freeMint() public callerIsUser {
        require(publicSale,"not now");
        require(!freeMinted[msg.sender], "already minted");
        require(totalSupply() + 2 <= MAX_SUPPLY,"sold out");
        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, 2);
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