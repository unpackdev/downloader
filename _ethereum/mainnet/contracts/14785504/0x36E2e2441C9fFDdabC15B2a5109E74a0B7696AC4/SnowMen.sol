// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC2981.sol";

contract SnowMen is ERC721, IERC2981, ERC721Enumerable, Ownable {    
    uint256 public constant MAX_ITEMS = 10000;    
    uint256 private _itemPrice = 0.018 ether;
    string private baseURI;    
    address public beneficiary;
    uint256 public royaltyPercent = 5;
        
    constructor(address _beneficiary, string memory _uri) ERC721("Snowmen Fighters Club", "SMF") {  
        beneficiary = _beneficiary;
        setBaseURI(_uri);

        _safeMint(beneficiary, 0);
        _safeMint(beneficiary, 1);
        _safeMint(beneficiary, 2);
        _safeMint(beneficiary, 3);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {            
        payable(beneficiary).transfer(address(this).balance);
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _itemPrice = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _itemPrice;
    }

    function mintSnowmans(uint numberOfTokens) public payable {        
        require(totalSupply() + numberOfTokens <= MAX_ITEMS, "Purchase would exceed max supply of items");                
        require(msg.value >= _itemPrice * numberOfTokens, "Ether value sent is not correct"); 
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();            
            if (mintIndex < MAX_ITEMS) {
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

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Non-existent token");
        return (beneficiary, _salePrice * royaltyPercent / 100);
    }
}