// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MetaWatchesGM is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _totalSupply;
    uint256 private constant MAX_SUPPLY = 17;
    string private _baseTokenURI = "https://www.metawatches.com/metadata/gm-2021/";
    
    constructor() ERC721("MetaWatchesGM", "MWGM") {}
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
        require(totalSupply() + amount <= MAX_SUPPLY, 'Exceeds max token supply');
        for (uint256 i = 0; i < amount; i++) {
            _totalSupply.increment();
            uint256 tokenId = _totalSupply.current();
            _safeMint(to, tokenId);
        }
    }
}