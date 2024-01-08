// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract LittleBois is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    
    // Set variables
    
    uint256 public LBois_SUPPLY = 6666;
    uint256 public LBois_PRICE = 60000000000000000 wei;
    bool private _saleActive = false;
    bool private _presaleActive = false;
    uint256 public constant presale_supply = 666;
    uint256 public  maxtxinpresale = 15;
    uint256 public  maxtxinsale = 20;

    string private _metaBaseUri = "";
    
    // Public Functions
    
    constructor() ERC721("Little Bois", "LBois") {
            
            
            for (uint16 i = 0; i < 10; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
        
        
    }
    
    function mint(uint16 numberOfTokens) public payable {
        require(isSaleActive(), "LBois sale not active");
        require(totalSupply().add(numberOfTokens) <= LBois_SUPPLY, "Sold Out");
        require(LBois_PRICE.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
        require(numberOfTokens<=20, "Max 20 are allowed" );

        _mintTokens(numberOfTokens);
    }
    
     function premint(uint16 numberOfTokens) public payable {
        require(ispreSaleActive(), "Presale Of LBois is not active");
        require(totalSupply().add(numberOfTokens) <= presale_supply, "Insufficient supply, Try in public sale");
        require(LBois_PRICE.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
        require(numberOfTokens<=15, "Max 15 are allowed" );
        _mintTokens(numberOfTokens);
    }
    
    
    function Giveaway(address to, uint16 numberOfTokens) external onlyOwner {
          for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(to, tokenId);
        }
    }
    
    function isSaleActive() public view returns (bool) {
        return _saleActive;
    }
    
    function ispreSaleActive() public view returns (bool) {
        return _presaleActive;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "", uint256(tokenId).toString()));
    }
    
    // Owner Functions

    function Flipsalestatus() external onlyOwner {
        _saleActive = !_saleActive;
    }
    
    function Flippresalestatus() external onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }
    
    function setsupply(uint256 _LBoisupply ) external onlyOwner {
        LBois_SUPPLY = _LBoisupply;
    }
    
    function withdrawAll() external onlyOwner {
                payable(msg.sender).transfer(address(this).balance);
    }

    // Internal Functions
    
    function _mintTokens(uint16 numberOfTokens) internal {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }

    function _baseURI() override internal view returns (string memory) {
        return _metaBaseUri;
    }
    

    // The following functions are overrides required by Solidity.

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
}