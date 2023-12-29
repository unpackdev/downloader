// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CowboyPunks is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    
    // Set variables
    
    uint256 public constant CBP_SUPPLY = 10000;
    uint256 public constant CBP_PRICE = 30000000000000000 wei;
    bool private _saleActive = false;
    string private _metaBaseUri = "https://www.cowboypunks.com/tokens/";
    
    // Public Functions
    
    constructor() ERC721("Cowboy Punks", "CBP") {}
    
    function mint(uint16 numberOfTokens) public payable {
        require(isSaleActive(), "Cowboy sale not active");
        require(totalSupply().add(numberOfTokens) <= CBP_SUPPLY, "Insufficient supply");
        require(CBP_PRICE.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
        _mintTokens(numberOfTokens);
    }
    
    function isSaleActive() public view returns (bool) {
        return _saleActive;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "metadata/", uint256(tokenId).toString()));
    }
    
    // Owner Functions

    function setSaleActive(bool active) external onlyOwner {
        _saleActive = active;
    }

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, 'Insufficient balance');
        payable(msg.sender).transfer(amount);
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