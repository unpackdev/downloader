// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract PremierJerseys is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    uint256 public tokenPrice = 20000000000000000; // 0.02 ETH
    uint256 public reserveRemaining = 150; // reserve for the team
    string public baseURI = "ipfs://bafybeiccmqazaudylu5wps4rpo45ceelk3dr4drjknahrb5gxzugn6uwpa/";

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINT_AT_ONCE = 20;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("PremierJerseys", "PRJR") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // END-USER FUNCTIONS

    function getMintedCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function mintJersey(address _to, uint256 _count) public payable {
        require(_count <= MAX_MINT_AT_ONCE, "You can mint at most 20 tokens at once!");
        require(_tokenIdCounter.current() + _count < MAX_SUPPLY, "Insufficient token supply");
        require(msg.value >= tokenPrice * _count, "Insufficient Ether sent");

        while (_count > 0) {
            _safeMint(_to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            _count -= 1;
        }
    }

    // OWNER FUNCTIONS

    function reserveJersey(address _to, uint256 _count) public onlyOwner {
        require(_tokenIdCounter.current() + _count < MAX_SUPPLY, "Insufficient token supply");
        require(_count <= reserveRemaining, "Insufficient token reserve");

        reserveRemaining -= _count;
        while (_count > 0) {
            _safeMint(_to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            _count -= 1;
        }
    }

    function setTokenPrice(uint256 _price) public onlyOwner {
        tokenPrice = _price;
    }

    function setBaseURI(string memory _value) public onlyOwner {
        baseURI = _value;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
