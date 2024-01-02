// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ERC165Base.sol";
import "./ERC1155Base.sol";
import "./ERC1155Enumerable.sol";
import "./ERC1155EnumerableInternal.sol";
import "./ERC1155Metadata.sol";
import "./ISolidStateERC1155.sol";
import "./ERC1155Pausable.sol";

/**
 * @title SolidState ERC1155 implementation
 */
abstract contract SolidStateERC1155 is
    ISolidStateERC1155,
    ERC1155Base,
    //ERC1155Pausable,
    ERC1155Enumerable,
    ERC1155Metadata,
    ERC165Base
{
    /**
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
