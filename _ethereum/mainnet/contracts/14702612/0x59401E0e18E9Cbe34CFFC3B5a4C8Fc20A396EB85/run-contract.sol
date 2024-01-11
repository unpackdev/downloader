// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract Titano is ERC721, ERC721URIStorage, Ownable {
    mapping(string => uint8) existingURIs;

    constructor() ERC721("Titano", "titano") {}

    function payToMint(
        address wallet,
        uint256 tokenId,
        string memory metadata
    ) public payable {
        require(existingURIs[metadata] != 1, "NFT already minted!");
        require(msg.value >= 0.02 ether, "Need to pay up!");

        _safeMint(wallet, tokenId);
        _setTokenURI(tokenId, metadata);

        existingURIs[metadata] = 1;

        withdraw();
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function withdraw() public returns (bool) {
        payable(owner()).transfer(address(this).balance);
        return true;
    }
}
