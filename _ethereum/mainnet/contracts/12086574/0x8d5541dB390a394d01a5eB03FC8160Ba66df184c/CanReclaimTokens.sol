// SPDX-License-Identifier: GPL-3.0-or-later
// KPR Liquidity Mining
// Copyright (C) 2020 Talo Research Pte. Ltd.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity 0.6.9;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract CanReclaimTokens is Ownable {
    using SafeERC20 for ERC20;

    mapping(address => bool) private recoverableTokensBlacklist;

    constructor() public {}

    function blacklistRecoverableToken(address _token) public onlyOwner {
        recoverableTokensBlacklist[_token] = true;
    }

    /// @notice Allow the owner of the contract to recover funds accidentally
    /// sent to the contract.
    function recoverTokens(address _token) external onlyOwner {
        require(
            !recoverableTokensBlacklist[_token],
            "CanReclaimTokens: token is not recoverable"
        );

        ERC20(_token).safeTransfer(
            msg.sender,
            ERC20(_token).balanceOf(address(this))
        );
    }
}