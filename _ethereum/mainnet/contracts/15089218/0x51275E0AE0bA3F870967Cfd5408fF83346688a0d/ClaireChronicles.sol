// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Ownable.sol";
import "./ERC721K.sol";

contract ClaireChronicles is Ownable, ERC721K {

    uint256 public nextIndexToAssign = 1;

    constructor() ERC721K("ClaireChronicles", "CLAIRE") {}

    function mint(address to, string memory uri) public onlyOwner {
        super._mint(to, nextIndexToAssign);
        super._setTokenURI(nextIndexToAssign, uri);
        nextIndexToAssign++;
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        super._setTokenURI(tokenId, uri);
    }

}
