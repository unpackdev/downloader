// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract NFT_Minter is ERC721, Pausable, Ownable {
    constructor() ERC721("Asuka_Kirara_LimitedNFT", "AKLTTX") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmaAp3xxAp71PUHUdTwpT6B4KLpVdQDy4LnMp1skHAVFH8/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
