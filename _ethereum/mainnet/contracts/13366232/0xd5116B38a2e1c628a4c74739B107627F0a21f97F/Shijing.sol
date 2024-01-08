// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Shijing is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant MAX_SUPPLY = 311;
    uint256 public constant MAX_PURCHASE = 10;
    uint256 public constant PRICE = 0.1 * 10 ** 18;

    constructor() ERC721("Shijing", "SHI") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmdkwZBpyrQc1pppt5rC24xq3sAZFaMhdtCSnvZG6rWefK/";
    }

    function mint(uint256 amount) public payable {
        require(totalSupply() < MAX_SUPPLY, "Shijing: Purchase has ended");
        require(amount > 0, "Shijing: Amount is zero");
        require(amount <= MAX_PURCHASE, "Shijing: Amount exceeds MAX_PURCHASE");
        require(totalSupply() + amount <= MAX_SUPPLY, "Shijing: Exceeds MAX_SUPPLY");
        require(PRICE * amount == msg.value, "Shijing: PRICE error");

        for (uint i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
