// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721.sol";
import "./IERC2981.sol";

contract MockErc721_Erc2981 is ERC721, IERC2981 {
    uint256 public maxTokenId;
    mapping(uint256 => string) public tokenURIs;

    constructor(string memory name, string memory symbol)
    ERC721(name, symbol)
    {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
        if (tokenId > maxTokenId) {
            maxTokenId = tokenId;
        }
    }

    function bulkMint(
        address to,
        uint256 startTokenId,
        uint256 amount
    ) external {
        require(startTokenId > maxTokenId, "Token id too low");
        for (uint256 i; i < amount; ++i) {
            _mint(to, i + startTokenId);
        }
        maxTokenId = startTokenId + amount;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return tokenURIs[id];
    }

    function setTokenURI(uint256 tokenId, string memory uri) external {
        tokenURIs[tokenId] = uri;
    }

    // ERC2981 Part
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(0);
        royaltyAmount = salePrice * 5000;
    }
}