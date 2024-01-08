// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract SANTAFORCE is ERC721, Ownable {
    
    using Strings for uint256;
    
    bool public isSale = false;
    bool public isMintRef = false;
    uint256 public currentToken = 0;
    uint256 public maxSupply = 10000;
    uint256 public price = 0.08 ether;
    string public metaUri = "https://santaforce.io/tokens/";
    
    constructor() ERC721("Santa Force", "SantaNFT") {}
    
    // Mint Functions

    function mint(uint256 quantity) public payable {
        require(isSale, "Public Sale is Not Active");
        require((currentToken + quantity) <= maxSupply, "Quantity Exceeds Tokens Available");
        uint256 pricenow = price;
        if (quantity >= 15) {
            pricenow = 0.06 ether;
        } else if (quantity >= 8) {
            pricenow = 0.07 ether;
        }
        require((pricenow * quantity) <= msg.value, "Ether Amount Sent Is Incorrect");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, currentToken);
            currentToken = currentToken + 1;
        }
    }

    function mintRef(uint256 quantity, address ref) public payable {
        require(isSale, "Public Sale is Not Active");
        require(isMintRef, "Minting with Referral is Not Active");
        require((currentToken + quantity) <= maxSupply, "Quantity Exceeds Tokens Available");
        uint256 pricenow = price;
        if (quantity >= 15) {
            pricenow = 0.06 ether;
        } else if (quantity >= 8) {
            pricenow = 0.07 ether;
        }
        require((pricenow * quantity) <= msg.value, "Ether Amount Sent Is Incorrect");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, currentToken);
            currentToken = currentToken + 1;
        }
        if (ref != 0x0000000000000000000000000000000000000000) {
            require(payable(ref).send((pricenow * quantity * 30 / 100)));
        }
    }
    
    function ownerMint(address[] memory addresses) external onlyOwner {
        require((currentToken + addresses.length) <= maxSupply, "Quantity Exceeds Tokens Available");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], currentToken);
            currentToken = currentToken + 1;
        }
    }

    // Token URL and Supply Functions - Public

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), uint256(tokenId).toString(), ".json"));
    }
    
    function totalSupply() external view returns (uint256) {
        return currentToken;
    }
    
    // Setter Functions - onlyOwner

    function triggerSale() public onlyOwner {
        isSale = !isSale;
    }

    function triggerRef() public onlyOwner {
        isMintRef = !isMintRef;
    }

    function setMetaURI(string memory newURI) external onlyOwner {
        metaUri = newURI;
    }

    // Withdraw Function - onlyOwner

    function withdraw() external onlyOwner {
        uint256 twoPercent = address(this).balance*2/100;
        uint256 remaining = address(this).balance*98/100;
        require(payable(0x4fF30f9e84fCD227f59CE788869aeAF7e4da9915).send(twoPercent));
        require(payable(0x0ECbE30790B6a690D4088B70dCC27664ca530D55).send(remaining));
    }

    // Internal Functions

    function _baseURI() override internal view returns (string memory) {
        return metaUri;
    }
    
}