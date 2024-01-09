// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract HexApeYachtClubHonorary is ERC721Enumerable, ReentrancyGuard, Ownable {
    constructor() ERC721("HexApeYachtClubHonorary", "HAYCHON") Ownable() {}

    /// Token URI
    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        string memory uri = string(
            abi.encodePacked(
                "https://gateway.pinata.cloud/ipfs/QmT5fiK3CyVX416EZAiihbor2wxTvbsu5pfnwbmcYmvxgT/",
                Strings.toString(tokenId+1),
                ".png"
            )
        );
        return uri;
    }

    /// Reserve for Owner
    function reserveForOwner() public onlyOwner returns (uint256) {
        for (uint256 i = 0; i < 20; i++) {
            _safeMint(msg.sender, i);
        }
        return totalSupply();
    }

    /// Withdraw for owner
    function withdraw() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        return true;
    }
}
