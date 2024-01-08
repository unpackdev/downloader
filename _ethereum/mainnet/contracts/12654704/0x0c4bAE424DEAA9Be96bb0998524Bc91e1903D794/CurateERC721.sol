// contracts/CurateERC721.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract CurateERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;

    constructor() public ERC721("Curate", "XCUR") {}

    function awardItem(address owner, string memory tokenURI, uint256 tokenId)
        public
        returns (uint256)
    {

        _mint(owner, tokenId);
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }
}