// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Math.sol";
import "./IMysteryNFT_S.sol";


contract MysteryNFT is ERC721Upgradeable, OwnableUpgradeable, IMysteryNFT_S {
    MysteryNFT_S[] private NFTs;

    function initialize() public initializer {
        ERC721Upgradeable.__ERC721_init('MysteryNFT', 'MysteryNFT');
        OwnableUpgradeable.__Ownable_init();
        _setBaseURI("https://ipfs.io/ipfs/");
    }

    function mint(address _to, MysteryNFT_S memory _nft,string memory _tokenURI) external onlyOwner returns (uint256 tokenId) {
        tokenId = NFTs.length.add(1);
        _nft.tokenId = uint32(tokenId);
        NFTs.push(_nft);
        super._safeMint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function burn(uint256 _tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: burn caller is not owner or approved");
        _burn(_tokenId);
    }
    function getNFTByTokenId(uint256 _tokenId) public view returns (MysteryNFT_S memory) {
        require(_tokenId > 0, "tokenId can not below zero");
        return NFTs[_tokenId.sub(1)];
    }

    function getNFTs(uint256 page) external view returns (MysteryNFT_S[] memory,uint) {
        require(page >= 1, "page must >= 1");
        uint256 size = 50;
        uint256 balance = balanceOf(msg.sender);
        uint256 from = (page - 1).mul(size);
        uint256 to = Math.min(page.mul(size), balance);
        if (from >= balance) {
            from = 0;
            to = balance;
        }
        MysteryNFT_S[] memory nfts = new MysteryNFT_S[](to-from);
        for (uint256 i = 0; from < to; ++i) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, from);
            nfts[i] = NFTs[tokenId.sub(1)];
            ++from;
        }
        return (nfts,balance);
    }
}