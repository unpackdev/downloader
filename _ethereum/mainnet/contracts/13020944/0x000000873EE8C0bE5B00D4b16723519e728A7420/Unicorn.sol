// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract Unicorn is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string public constant DEFAUL_BASE_URI = "ipfs://QmW9onACAGVfFhLTUxeuDYmxzPb7BrJp78bLbhTFFBoSXQ";
    string private baseURI;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PURCHASE = 10;
    uint256 public constant PRICE = 0.01 * 10 ** 18;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Unicorn", "UNI") {}

    function mint(uint256 amount) public payable {
        require(totalSupply() < MAX_SUPPLY, "Unicorn: Sale has ended");
        require(amount > 0, "Unicorn: Cannot buy 0");
        require(amount <= MAX_PURCHASE, "Unicorn: You may not buy that many NFTs at once");
        require(totalSupply().add(amount) <= MAX_SUPPLY, "Unicorn: Exceeds max supply");
        require(PRICE.mul(amount) == msg.value, "Unicorn: Ether value sent is not correct");

        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
    
    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory uri = super.tokenURI(tokenId);
        if (bytes(uri).length == 0) {
            return DEFAUL_BASE_URI;
        }
        
        return uri;
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
