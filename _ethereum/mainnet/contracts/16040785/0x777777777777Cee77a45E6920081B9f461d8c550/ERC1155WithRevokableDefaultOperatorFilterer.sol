// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1155Supply.sol";
import "./RevokableDefaultOperatorFilterer.sol";

abstract contract ERC1155WithRevokableDefaultOperatorFilterer is
    ERC1155Supply,
    RevokableDefaultOperatorFilterer
{
    // ============================================================================
    // ========================== OPENSEA OPERATOR FILTER =========================
    // ============================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}
