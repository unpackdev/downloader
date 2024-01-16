// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";

contract EricEscapesTheMerge is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 5875;
    uint256 public constant MAX_FREE = 1509;
    uint256 public reservedTokensMinted = 0;

    uint256 public PRICE = 0.001509 ether; 
    
    bool public publicIsActive = false;
    bool public freeIsActive = false;

    string public uriSuffix = ".json";
    string public baseURI = "";

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721(_tokenName, _tokenSymbol) {
    }

    //Mint function
    function mint() public payable {
        require(publicIsActive, "Sale must be active to mint");
        require(totalSupply() + 1 <= MAX_TOKENS - (5 - reservedTokensMinted) , "Purchase would exceed max supply");
        require(msg.value >= PRICE * 1, "Insufficient funds!");

        _safeMint(msg.sender, totalSupply() + 1);
    }

     //Free Mint function
    function freeMint() public payable {
        require(freeIsActive, "Sale must be active to mint");
        require(totalSupply() + 1 <= MAX_FREE , "Purchase would exceed max supply");

        _safeMint(msg.sender, totalSupply() + 1);
    }

     function mintReservedTokens(uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= 5, "This amount is more than max allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
            reservedTokensMinted++;
        }
    }
    


    //Utility function
    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function flipSaleState() external onlyOwner 
    {
        publicIsActive = !publicIsActive;
    }
    
    function flipFreeSaleState() external onlyOwner 
    {
        freeIsActive = !freeIsActive;
    }

    function withdraw() external
    {
        require(msg.sender == owner(), "Invalid sender");
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer  failed");
   
    }

    ////
    //URI management part
    ////   

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
            baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
  
}