/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./IERC20.sol";

/**
 * @title Reservoir
 *
 * @dev The contract is used to keep tokens with the function
 * of transfer them to another target address (it is assumed that
 * it will be a contract address).
 */
contract Reservoir {
    IERC20 public token;
    address public target;

    /**
     * @dev A constructor sets the address of token and
     * the address of the target contract.
     */
    constructor(IERC20 _token, address _target) public {
        token = _token;
        target = _target;
    }

    /**
     * @dev Transfers a certain amount of tokens to the target address.
     *
     * Requirements:
     * - msg.sender should be the target address.
     *
     * @param requestedTokens The amount of tokens to transfer.
     */
    function drip(uint256 requestedTokens)
        external
        returns (uint256 sentTokens)
    {
        address target_ = target;
        IERC20 token_ = token;
        require(msg.sender == target_, "Reservoir: permission denied");

        uint256 reservoirBalance = token_.balanceOf(address(this));
        sentTokens = (requestedTokens > reservoirBalance)
            ? reservoirBalance
            : requestedTokens;

        token_.transfer(target_, sentTokens);
    }
}
