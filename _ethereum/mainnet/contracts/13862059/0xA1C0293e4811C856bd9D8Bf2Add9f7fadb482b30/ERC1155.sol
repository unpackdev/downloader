/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0
// Based on OpenZeppelin Contracts v4.3.2 (token/ERC1155/ERC1155.sol)

pragma solidity 0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";

 /**
  * @author Modified by Kam Amini <kam@arteq.io> <kam@2b.team> <kam.cpp@gmail.com>
  *
  * @notice Use at your own risk
  *
  * Note: 2B has modified the original code to cover its needs as
  * part of artèQ Investment Fund ecosystem
  */
abstract contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    // arteQ: we made this field public in order to distribute profits in the token contract
    mapping(uint256 => mapping(address => uint256)) public _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {_setURI}.
     */
    constructor() {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved "
        );
        _safeTransferFrom(_msgSender(), from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address /* from */,
        address /* to */,
        uint256[] memory /* ids */,
        uint256[] memory /* amounts */,
        bytes memory /* data */
    ) public virtual override {
        revert("ERC1155: not implemented");
    }

    function _safeTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        // arteQ: we have to read the returned amount again as it can change in the function
        uint256[] memory amounts = _asArray(amount, 2);
        _beforeTokenTransfer(operator, from, to, id, amounts, data);
        uint256 fromAmount = amounts[0];
        uint256 toAmount = amounts[1];

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= fromAmount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - fromAmount;
        }
        _balances[id][to] += toAmount;

        emit TransferSingle(operator, from, to, id, amount);
    }

    function _initialMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, id, _asArray(amount, 2), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address /* operator */,
        address /* from */,
        address /* to */,
        uint256 /* id */,
        uint256[] memory /* amounts */,
        bytes memory /* data */
    ) internal virtual {}

    function _asArray(uint256 element, uint len) private pure returns (uint256[] memory) {
        if (len == 1) {
            uint256[] memory array = new uint256[](1);
            array[0] = element;
            return array;
        } else if (len == 2) {
            uint256[] memory array = new uint256[](2);
            array[0] = element;
            array[1] = element;
            return array;
        }
        revert("ERC1155: length must be 1 or 2");
    }
}
