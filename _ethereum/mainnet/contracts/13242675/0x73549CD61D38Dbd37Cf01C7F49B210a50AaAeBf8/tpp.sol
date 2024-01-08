// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./SafeMath.sol";


contract TPP is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    using SafeMath for uint256;

    string private _baseURIPrefix;

    uint private constant maxTokensPerTransaction = 30;
    uint256 private tokenPrice = 50000000000000000; //0.03 ETH
    uint256 private constant nftsNumber = 10000;
    uint256 private constant nftsPublicNumber = 9950;
    

    constructor() ERC721("Tall People Problem", "TPP") {
        _tokenIdCounter.increment();
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function directMint(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Tokens number to mint must exceed number of public tokens");
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
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
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function buyTPP(uint tokensNumber) whenNotPaused public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}
