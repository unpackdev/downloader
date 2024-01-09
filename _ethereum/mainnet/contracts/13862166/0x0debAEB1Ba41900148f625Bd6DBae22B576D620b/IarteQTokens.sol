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

/// @author Kam Amini <kam@arteq.io> <kam@2b.team> <kam.cpp@gmail.com>
///
/// @title An interface which allows ERC-20 tokens to interact with the
/// main ERC-1155 contract
///
/// @notice Use at your own risk
interface IarteQTokens {
    function compatBalanceOf(address origin, address account, uint256 tokenId) external view returns (uint256);
    function compatTotalSupply(address origin, uint256 tokenId) external view returns (uint256);
    function compatTransfer(address origin, address to, uint256 tokenId, uint256 amount) external;
    function compatTransferFrom(address origin, address from, address to, uint256 tokenId, uint256 amount) external;
    function compatAllowance(address origin, address account, address operator) external view returns (uint256);
    function compatApprove(address origin, address operator, uint256 amount) external;
}

