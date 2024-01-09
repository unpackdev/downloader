// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MetaWatchesSingularity is ERC721, Ownable {
    using Counters for Counters.Counter;

    string private _baseTokenURI;
    Counters.Counter private _totalSupply;

    constructor(string memory baseURI) ERC721('MetaWatchesSingularity', 'MWS') {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply.current();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            _totalSupply.increment();
            uint256 tokenId = _totalSupply.current();
            _safeMint(to, tokenId);
        }
    }
}
