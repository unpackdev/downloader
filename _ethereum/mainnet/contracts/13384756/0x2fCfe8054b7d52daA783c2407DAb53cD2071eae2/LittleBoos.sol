// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract LittleBoos is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    
    // Set variables
    
    uint256 public constant BOO_SUPPLY = 9999;
    uint256 public constant BOO_PRICE = 70000000000000000 wei;
    bool private _saleActive = false;
    string private _metaBaseUri = "https://www.littleboos.com/tokens/"; // will be updated to ipfs
    
    // Public Functions
    
    constructor() ERC721("LittleBoos", "LBS") {}
    
    function mint(uint16 numberOfTokens) public payable {
        require(isSaleActive(), "LittleBoos sale not active");
        require(balanceOf(msg.sender).add(numberOfTokens) <= 20, "You cannot have more than 20 LittleBoos in a wallet");
        require(totalSupply().add(numberOfTokens) <= BOO_SUPPLY, "Insufficient LittleBoos available, please try to mint less LittleBoos");
        require(BOO_PRICE.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
        _mintTokens(numberOfTokens);
    }
    
    function isSaleActive() public view returns (bool) {
        return _saleActive;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), uint256(tokenId).toString(), ".json"));
    }
    
    // Owner Functions

    function setSaleActive(bool active) external onlyOwner {
        _saleActive = active;
    }

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
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