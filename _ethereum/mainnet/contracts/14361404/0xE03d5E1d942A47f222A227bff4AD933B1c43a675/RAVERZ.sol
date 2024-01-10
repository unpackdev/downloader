// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

contract RAVERZ is ERC721, Ownable, PaymentSplitter {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public mintRate = 0.025 ether;

    constructor(address[] memory _payees, uint256[] memory _shares) ERC721("RAVERZ", "RAV") PaymentSplitter(_payees, _shares) payable {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmYMDWpyKWQbNggsWg8GuQBoSLvYdWwvjjHfH7JheEALYs/";
    }

    function safeMint(address to) public payable {
        require(msg.value >= mintRate, 'the minimum price is 0.025 ether');
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
