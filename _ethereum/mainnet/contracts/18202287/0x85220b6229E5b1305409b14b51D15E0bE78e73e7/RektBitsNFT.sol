// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract RektBitsNFT is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    uint256 maxSupply = 8814;
    string private _baseUri;
    string private _baseExtension = ".json";


    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("RektBits", "RektBits") {
        
    }
    

  function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, Strings.toString(tokenId), _baseExtension));
    }

    function setBaseURI(string calldata baseUri) external onlyOwner() {
        _baseUri = baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //Add Payments & Limiting of supply
    function getRekt() public payable{
        require(msg.value == 0.03 ether, "Not enough ETH");
        require(totalSupply() < maxSupply, "Minted out");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    //withdraw function
    function withdraw(address _addr) external onlyOwner{
        uint256 balance =address(this).balance;
        payable (_addr).transfer(balance);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}