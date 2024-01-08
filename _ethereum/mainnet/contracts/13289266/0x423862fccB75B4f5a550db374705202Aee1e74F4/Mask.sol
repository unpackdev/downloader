// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Afromasks is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PURCHASE = 100;
    uint256 public constant PRICE = 0.01 ether;

    constructor() ERC721("Afromasks", "aMASK") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmXvb2rTZzXs7A4nb6PUB78521wiAqHrrjYmtSh6aATenS/";
    }

    function mint(uint256 amount) public payable {
        require(totalSupply() < MAX_SUPPLY, "Afromasks: MAX_SUPPLY");
        require(amount > 0, "Afromasks: amount");
        require(amount <= MAX_PURCHASE, "Afromasks: amount <= MAX_PURCHASE");
        require(totalSupply() + amount <= MAX_SUPPLY, "Afromasks: MAX_SUPPLY");
        require(PRICE * amount == msg.value, "Afromasks: PRICE");

        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
    
    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.

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
}
