// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title: The Zombie gaming club
// @author: The Zombie gaming team

import "./Context.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract Zombie is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    uint public constant maxPurchase = 10;
    uint256 public constant MAX_ZOMBIES = 8000;

    uint256 private _zombiePrice = 80000000000000000; //0.08 ETH
    string private baseURI;

    address a1 = 0x86853cDAD1EfCE50A83fC322cA6B9B5FB81B4bCb;
    address a2 = 0x7dA647dDbb52Bc5d9FA0916A25369B480e7b46c5;
    address a3 = 0x8980712223b2e7F3602a1C513A63C1f9Da3A3dae;
    address a4 = 0x8D000376FbB84C90E3617663209fF650FcC64909;

    constructor() ERC721("The Zombie Gaming club", "ZGC") {
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
        _zombiePrice = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _zombiePrice;
    }

    function mintZombies(uint numberOfTokens) public payable {
        require(numberOfTokens <= maxPurchase, "Can only mint 10 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_ZOMBIES, "Purchase would exceed max supply of Zombies");
        require(_zombiePrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_ZOMBIES) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }      

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 4;
        require(payable(a1).send(_each));
        require(payable(a2).send(_each));
        require(payable(a3).send(_each));
        require(payable(a4).send(_each));
    } 
}
