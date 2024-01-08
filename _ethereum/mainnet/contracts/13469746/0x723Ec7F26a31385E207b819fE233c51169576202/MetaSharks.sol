// SPDX-License-Identifier: MIT
// Authored by NoahN ✌️

pragma solidity ^0.8.3;

import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract MetaSharks is ERC721Enumerable{
    using SafeMath for uint256;
    using Strings for uint256;
    
    bool public mintPassSale = false;
    bool public sharkPresale = false;
    bool public sharkSale = false;
    address public owner;
    address constant admin = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;
    mapping(address => uint) public purchasedPasses;
    uint public constant mintPassPrice = 5000000000000000; // 0.005 ETH
    uint public constant mintSharkPrice = 65000000000000000; // 0.065 ETH
    string public baseTokenURI;
    mapping(uint => uint) public mintPassUses;
    uint public mintPassNextId = 0;
    uint public constant mintPassMaxSupply = 1000;
    
    uint public metaSharkNextId = 1000;
    uint public constant metaSharkMaxSupply = 11045;
    
    constructor(string memory _baseTokenURI)  ERC721("MetaSharks", "MS"){
        owner = msg.sender;
        baseTokenURI = _baseTokenURI;
    }
    
    modifier onlyTeam {
        require(msg.sender == owner || msg.sender == admin, "You are not the owner.");
        _;
    }

    function mintMetaShark(uint mintPassId, uint mintNum) external payable{
        require(mintNum < 11, "That's too many for one transaction!");
        require(metaSharkNextId + mintNum < metaSharkMaxSupply, "No more MetaSharks left!");
        require(sharkSale || sharkPresale, "Not time to buy a MetaShark!");
        require(msg.value == mintNum * mintSharkPrice, "Wrong amount of ether sent!");
        if(sharkPresale){
            require(mintPassUses[mintPassId] + mintNum < 11, "That's too many for this pass!");
            require(ownerOf(mintPassId) == msg.sender, "You don't own that MintPass!");
            mintPassUses[mintPassId] += mintNum;
        }
        
		for (uint i = 0; i < mintNum; i++) {
			_safeMint(msg.sender, metaSharkNextId);
			metaSharkNextId++;
		}
        
    }
    
	function giftSharkPass(address recipient) external onlyTeam {
        require(mintPassNextId + 1 < mintPassMaxSupply, "No more MintPasses left!");
	    _safeMint(recipient, mintPassNextId);
	    mintPassNextId++;
	}
	
	function giftMetaShark(address recipient) external onlyTeam {
        require(metaSharkNextId + 1 < metaSharkMaxSupply, "No more MetaSharks left!");
	    _safeMint(recipient, metaSharkNextId);
	    metaSharkNextId++;
	}
	
    function mintSharkPass()  external  payable {
        require(mintPassSale, "It is not time to buy a MintPass!");
        require(purchasedPasses[msg.sender] < 3, "You can only purchase 3 MintPasses!");
        require(mintPassNextId + 1 < mintPassMaxSupply, "No more MintPasses left!");
        require(msg.value == mintPassPrice);
        _safeMint(msg.sender, mintPassNextId);
        mintPassNextId++;
        purchasedPasses[msg.sender] += 1;
    }
    
    function withdraw()  public onlyTeam {
        payable(admin).transfer(address(this).balance.div(15)); 
        payable(owner).transfer(address(this).balance); 
    }

    function setBaseURI(string memory baseURI) public onlyTeam {
        baseTokenURI = baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(tokenId < mintPassMaxSupply){
            return string(abi.encodePacked(baseTokenURI, tokenId.toString(), "-", mintPassUses[tokenId].toString(), ".json"));   
        } else {
            return string(abi.encodePacked(baseTokenURI, tokenId.toString(),".json"));
        }
    }
    
    function toggleMintPassSale() public onlyTeam{
        mintPassSale = !mintPassSale;
    }
    
    function toggleSharkSale() public onlyTeam {
        sharkSale = !sharkSale;
    }
	
    function toggleSharkPresale() public onlyTeam {
        sharkPresale = !sharkPresale;
    }
    
    function getMintPassCount() public view returns(uint) {
        return mintPassNextId;
    }
    
    function getMetaSharkCount() public view returns(uint) {
        return metaSharkNextId - 1000;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }
}