// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";

contract MetaWatchesSchachterWelkerCollection is ERC721, Ownable {
    uint256 private constant TOTAL_SUPPLY = 10;
    string private _baseTokenURI = "https://www.metawatches.com/metadata/schachter-welker/";

    constructor() ERC721("MetaWatchesSchachterWelkerCollection", "MWSW") {
        for (uint256 tokenId = 1; tokenId <= TOTAL_SUPPLY; tokenId++) {
            _safeMint(owner(), tokenId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}