/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
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

pragma solidity 0.8.1;

import "./ERC20.sol";
import "./IERC721.sol";
import "./AccountLocker.sol";
import "./BatchTransferEnabled.sol";
import "./TaskManagedERC20VaultEnabled.sol";
import "./TaskManagedERC721VaultEnabled.sol";
import "./TaskManagedERC1155VaultEnabled.sol";

/// @author Kam Amini <kam@arteq.io> <kam.cpp@gmail.com>
///
/// @notice Use at your own risk
contract QLINDO is
  ERC20,
  AccountLocker,
  BatchTransferEnabled,
  TaskManagedERC20VaultEnabled,
  TaskManagedERC721VaultEnabled,
  TaskManagedERC1155VaultEnabled
{
    constructor(address taskManager)
      ERC20("Qlindo Realestate Investment Token", "QLINDO")
    {
        require(taskManager != address(0), "QLINDO: zero address set for task manager");
        _setTaskManager(taskManager);
        _mint(_getTaskManager(), 10 * 10 ** 9); // 10 billion tokens
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address /*to*/,
        uint256 /*amount*/
    ) internal virtual override {
        require(!_isLocked(from), "QLINDO: account cannot transfer tokens");
    }

    function _batchTransferSingle(
        address source,
        address to,
        uint256 amount
    ) internal virtual override {
        _transfer(source, to, amount);
    }

    receive() external payable {
        revert("QLINDO: cannot accept ether");
    }

    fallback() external payable {
        revert("QLINDO: cannot accept ether");
    }
}
