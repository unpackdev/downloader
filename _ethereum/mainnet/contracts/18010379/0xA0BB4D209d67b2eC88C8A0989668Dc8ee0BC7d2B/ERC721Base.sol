// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IERC721Base.sol";
import "./ERC721BaseInternal.sol";
import "./IERC721.sol";

import "./RevokableOperatorFiltererUpgradeable.sol";

/**
 * @title Base ERC721 implementation, including the operator filter pattern
 */
abstract contract ERC721Base is IERC721Base, ERC721BaseInternal, RevokableOperatorFiltererUpgradeable {
    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _isApprovedForAll(account, operator);
    }

    /*//////////////////////////////////////////////////////////////
                        OPERATOR FILTER OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public onlyAllowedOperatorApproval(operator) {
        _setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        _approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        _safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        _safeTransferFrom(from, to, tokenId, data);
    }
}
