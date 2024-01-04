// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC721.sol";

contract NFTFinanceDomainNameToken is ERC721 {
    bool mintingEnabled = true;

    constructor(string memory tokenURI, address receiver) ERC721("NFT.finance Domain Name", "NFTFINTLD") public {
        uint256 tokenID = 1;

        _mint(receiver, tokenID);
        _setTokenURI(tokenID, tokenURI);
        mintingEnabled = false;
    }

    function _mint(address to, uint256 tokenId) internal override {
        require(mintingEnabled, "Minting disabled forever.");

        super._mint(to, tokenId);
    }
}
