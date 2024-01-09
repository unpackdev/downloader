// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Doodleyzoo is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    
    // Set variables
    
    uint256 public Dz_SUPPLY = 11000;
    uint256 public Dz_PRICE = 0.02 ether;
    bool private _saleActive = false;
    bool private _presaleActive = false;
    uint256 public constant presale_supply = 1000;
    uint256 public  maxtxinpresale = 15;
    uint256 public  maxtxinsale = 20;
    mapping(address => bool) public whitelist;



    string private _metaBaseUri = "";
    
    // Public Functions
    
    constructor() ERC721("Doodleyzoo", "Doodleyzoo") {
            
            
            for (uint16 i = 0; i < 10; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
        
        
    }
    
    function mint(uint16 numberOfTokens) public payable {
        require(isSaleActive(), "Doodleyzoo sale not active");
        require(totalSupply().add(numberOfTokens) <= Dz_SUPPLY, "Sold Out");
        require(Dz_PRICE.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
        _mintTokens(numberOfTokens);
    }
    
     function premint(uint16 numberOfTokens) public payable {
        require(ispreSaleActive(), "Presale Of Doodleyzoo is not active");
        require(whitelist[(msg.sender)]== true, "Not whitelisted is not active");
        require(totalSupply().add(numberOfTokens) <= presale_supply, "Insufficient supply, Try in public sale");
        require(Dz_PRICE.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
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
        return string(abi.encodePacked(_baseURI(), uint256(tokenId).toString(), ".json"));
    }
    
    // Owner Functions

    function Flipsalestatus() external onlyOwner {
        _saleActive = !_saleActive;
    }
      function addaddrtowhitelist(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length ; i++){
            whitelist[_address[i]] = true;
    }}
    
    function removeaddrfromwhitelist(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length ; i++){
            whitelist[_address[i]] = false;
    }}
    
    
    function veiwifwhitelisted(address _address) public view returns (bool) {
       return whitelist[_address];
    }
    
    
    function Flippresalestatus() external onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }
    
    function setsupply(uint256 _Doodleyzoosupply ) external onlyOwner {
        Dz_SUPPLY = _Doodleyzoosupply;
    }
    function setprice(uint256 _price ) external onlyOwner {
        Dz_PRICE= _price;
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