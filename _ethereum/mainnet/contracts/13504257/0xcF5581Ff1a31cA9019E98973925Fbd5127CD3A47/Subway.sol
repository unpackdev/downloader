// SPDX-License-Identifier: MIT
// Authored by NoahN ✌️

pragma solidity ^0.8.3;

import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract SubwayCards is ERC721Enumerable{
     using SafeMath for uint256;
     using Strings for uint256;
     
    bool public sale = false;
    address public owner;
    address constant admin = 0xCAE2c859148340705fF10C8Ef362274fdE9c1835;
    uint public constant tokenPrice = 88800000000000000; // .0888 eth
    string public baseTokenURI;

    uint public subwayCardNextId = 0;
    uint public constant subwayCardMaxSupply = 8005;
    
    constructor(string memory _baseTokenURI)  ERC721("NFTInsidersGuide", "NFTIG"){
        owner = msg.sender;
        baseTokenURI = _baseTokenURI;
    }
    
    modifier onlyTeam {
        require(msg.sender == owner || msg.sender == admin, "You are not on the team.");
        _;
    }
    
	function giftSubwayCards(address[] memory recipients) external onlyTeam {
        require(subwayCardNextId + recipients.length < subwayCardMaxSupply, "That would exceed the max supply!");
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], subwayCardNextId);
	        subwayCardNextId++;
        }
	}

    function mintSubwayCards(uint mintNum)  external  payable {
        require(subwayCardNextId + mintNum < subwayCardMaxSupply, "That would exceed the max supply!");
        require(mintNum < 11, "You can't mint that many at one time!");
        require(msg.value == tokenPrice * mintNum, "That's not the right amount of ETH!");
        require(sale, "It's not time to buy!");
        
         for (uint256 i = 0; i < mintNum; i++) {
            _safeMint(msg.sender, subwayCardNextId);
            subwayCardNextId++;
        }
	}
        
    
    function withdraw()  public onlyTeam {
        payable(admin).transfer(address(this).balance.div(5)); 
        payable(owner).transfer(address(this).balance);
    }
    
    function toggleSale() public onlyTeam {
        sale = !sale;
    }

    function setBaseURI(string memory baseURI) public onlyTeam {
        baseTokenURI = baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(),".json"));        
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }
}