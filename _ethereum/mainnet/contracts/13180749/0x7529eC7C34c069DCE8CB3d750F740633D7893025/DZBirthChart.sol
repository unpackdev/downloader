// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DZBirthChart is ERC721Enumerable, Ownable {

    string private _baseTokenURI;

    constructor(string memory baseTokenURI)
        ERC721("Divine Zodiac Birth Charts", "DZBC")
    {
        setBaseURI(baseTokenURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    // Allows for the early reservation of 100 zodiacs from the creators for promotional usage
    function airdropTokens(uint256[] memory tokenIds, address[] memory wallets) public onlyOwner {
        require(tokenIds.length < 50, "max 50 airdrops per transaction");
        uint count = tokenIds.length;

        for (uint256 index; index < count; index++) {
            _safeMint(wallets[index], tokenIds[index]);
        }
    }
}
