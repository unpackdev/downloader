//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract NFT is ERC721A {
    constructor() ERC721A("( F )orever Members 00", "FOR1") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return
            "ipfs://bafybeiceqnf4k3kxfd7wzbgvb5astg45fze5czlvv2z2pai4sz4bhx3pwa/meta/";
    }

    function mintToken(address to) public {
        require(_totalMinted() < 50, "Too many minted."); // if we exceed 50, stop minting
        _safeMint(to, 1);
    }
}
