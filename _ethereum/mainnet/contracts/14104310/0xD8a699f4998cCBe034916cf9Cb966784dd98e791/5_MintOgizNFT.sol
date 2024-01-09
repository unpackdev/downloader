// SPDX-License-Identifier: MIT

/*
_______/\\\\\__________/\\\\\\\\\\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\\\_        
 _____/\\\///\\\______/\\\//////////__\/////\\\///__\////////////\\\__       
  ___/\\\/__\///\\\___/\\\_________________\/\\\_______________/\\\/___      
   __/\\\______\//\\\_\/\\\____/\\\\\\\_____\/\\\_____________/\\\/_____     
    _\/\\\_______\/\\\_\/\\\___\/////\\\_____\/\\\___________/\\\/_______    
     _\//\\\______/\\\__\/\\\_______\/\\\_____\/\\\_________/\\\/_________   
      __\///\\\__/\\\____\/\\\_______\/\\\_____\/\\\_______/\\\/___________  
       ____\///\\\\\/_____\//\\\\\\\\\\\\/___/\\\\\\\\\\\__/\\\\\\\\\\\\\\\_ 
        ______\/////________\////////////____\///////////__\///////////////__

twitter: https://twitter.com/Ogiz_Nft_
web: https://ogiznft.com
*/

pragma solidity ^0.8.3;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
//import "./ERC721Full.sol";

contract MintOgizNFT is ERC721, Ownable{
    using Address for address;
    using Strings for uint256;

    uint256 public ethPrice = 0.04 ether;
    uint256 public ethPriceWhitelist = 0.02 ether;

    uint256 public totalSupply = 0;
    uint256 public maxSupply = 3333;
    uint256 public maxPerWallet = 10;
    uint256 public maxOwner = 50;

    bool public saleStarted = false;
    bool public isRevealed = false;

    string public baseURI = "";

    function togglePublicSaleStarted() external onlyOwner {
        saleStarted = !saleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed) {
            return super.tokenURI(tokenId);
        } else {
            return
                string(abi.encodePacked("", tokenId.toString()));
        }
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    constructor() payable ERC721("Ogiz NFT", "OGIZ") {
    }

    function mintPublic(uint256 quantity) public payable {
        require(saleStarted, "Sale has not started");
        require(totalSupply < maxSupply, "sold out");
        require(totalSupply + quantity <= maxSupply, "exceeds max supply");
        require(quantity <= maxPerWallet, "exceeds max per txn");
        require(msg.value >= ethPrice*quantity, "exceeds max per txn");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 newTokenId = totalSupply + 1;
            _safeMint(msg.sender, newTokenId);
            totalSupply++;
        }
    }

    function mintWhitelist(uint256 quantity) public payable {
        require(saleStarted, "Sale has not started");
        require(totalSupply < maxSupply, "sold out");
        require(totalSupply + quantity <= maxSupply, "exceeds max supply");
        require(quantity <= maxPerWallet, "exceeds max per txn");
        require(msg.value >= ethPriceWhitelist*quantity, "exceeds max per txn");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 newTokenId = totalSupply + 1;
            _safeMint(msg.sender, newTokenId);
            totalSupply++;
        }
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(totalSupply < maxSupply, "sold out");
        require(totalSupply + quantity <= maxSupply, "exceeds max supply");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 newTokenId = totalSupply + 1;
            _safeMint(to, newTokenId);
            totalSupply++;
        }
    }

    function withdraw() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256){
        return address(this).balance;
    }
}