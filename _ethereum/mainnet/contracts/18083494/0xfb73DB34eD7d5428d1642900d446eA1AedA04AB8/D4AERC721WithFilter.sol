// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./D4AERC721.sol";
import "./ID4AERC721Factory.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

contract D4AERC721WithFilter is D4AERC721, DefaultOperatorFiltererUpgradeable {
    function initialize(string memory name, string memory symbol, uint256) public virtual override initializer {
        __D4AERC721_init(name, symbol);
        __DefaultOperatorFilterer_init();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
