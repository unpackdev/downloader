// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC721.sol";
import "./Ownable.sol";

import "./IResetAccountConnector.sol";
import "./ITokenURIConnector.sol";

contract FodlNFT is ERC721, Ownable {
    bool private migrating;

    constructor(string memory name, string memory symbol) public ERC721(name, symbol) Ownable() {}

    function mint(address owner, uint256 nftId) external onlyOwner {
        _safeMint(owner, nftId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        ///@dev no need to reset account when migrating
        if (migrating) return;
        address foldingAccount = address(tokenId);
        IResetAccountConnector(foldingAccount).resetAccount(from, to, tokenId);
    }

    ///@notice Forward call to FoldingAccount represented by this tokenId
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address foldingAccount = address(tokenId);
        return ITokenURIConnector(foldingAccount).tokenURI();
    }

    function migrateLegacyNFT(
        FodlNFT sourceNFT,
        uint256 fromIndex,
        uint256 toIndex
    ) external onlyOwner {
        migrating = true;
        uint256 count = sourceNFT.totalSupply();
        if (toIndex == 0 || toIndex > count) toIndex = count;
        for (uint256 i = fromIndex; i < toIndex; i++) {
            uint256 tokenId = sourceNFT.tokenByIndex(i);
            _safeMint(sourceNFT.ownerOf(tokenId), tokenId);
        }
        migrating = false;
    }
}
