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

pragma solidity 0.8.0;

import "./Context.sol";
import "./ERC165.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IarteQTokens.sol";
import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <kam@arteq.io> <kam@2b.team> <kam.cpp@gmail.com>
///
/// @title ARTEQ token; the main asset in artèQ Investment Fund ecosystem
///
/// @notice Use at your own risk
contract ARTEQ is Context, ERC165, IERC20Metadata {

    uint256 public constant ARTEQTokenId = 1;

    address private _arteQTokensContract;

    address private _adminContract;

    modifier adminApprovalRequired(uint256 adminTaskId) {
        _;
        // This must succeed otherwise the tx gets reverted
        IarteQTaskFinalizer(_adminContract).finalizeTask(msg.sender, adminTaskId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    constructor(address arteQTokensContract, address adminContract) {
        _arteQTokensContract = arteQTokensContract;
        _adminContract = adminContract;
    }

    function name() external view virtual override returns (string memory) {
        return "arteQ Investment Fund Token";
    }

    function symbol() external view virtual override returns (string memory) {
        return "ARTEQ";
    }

    function decimals() external view virtual override returns (uint8) {
        return 0;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return IarteQTokens(_arteQTokensContract).compatTotalSupply(_msgSender(), ARTEQTokenId);
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return IarteQTokens(_arteQTokensContract).compatBalanceOf(_msgSender(), account, ARTEQTokenId);
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        IarteQTokens(_arteQTokensContract).compatTransfer(_msgSender(), recipient, ARTEQTokenId, amount);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        IarteQTokens(_arteQTokensContract).compatTransferFrom(_msgSender(), sender, recipient, ARTEQTokenId, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return IarteQTokens(_arteQTokensContract).compatAllowance(_msgSender(), owner, spender);
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        IarteQTokens(_arteQTokensContract).compatApprove(_msgSender(), spender, amount);
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueTokens(uint256 adminTaskId, IERC20 foreignToken, address to) external adminApprovalRequired(adminTaskId) {
        foreignToken.transfer(to, foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTRescue(uint256 adminTaskId, IERC721 foreignNFT, address to) external adminApprovalRequired(adminTaskId) {
        foreignNFT.setApprovalForAll(to, true);
    }

    receive() external payable {
        revert("ARTEQ: cannot accept ether");
    }

    fallback() external payable {
        revert("ARTEQ: cannot accept ether");
    }
}
