// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title: She Curly NFT
// @author: She Curly Team

import "./Context.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract SheCurlyNFT is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    uint public constant maxPurchase = 10;
    uint256 public constant MAX_ITEMS = 10000;

    uint256 private _mintPrice = 20000000000000000; //0.02 ETH
    string private baseURI;
    bool public saleIsActive = true;
    
    address private creator = 0xFeEd9A5290F5Ef2A060E98C531Ab8d533C3A2785;

    constructor() ERC721("She Curly NFT", "CRL") {
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}    

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _mintPrice = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _mintPrice;
    }

    function mintCurlies(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint NFT");
        require(numberOfTokens <= maxPurchase, "Can only mint 10 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_ITEMS, "Purchase would exceed max supply of NFT's");
        require(_mintPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_ITEMS) {
                _safeMint(msg.sender, mintIndex+1);
            }
        }
    }      

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(creator).send(_balance));
    } 
}
