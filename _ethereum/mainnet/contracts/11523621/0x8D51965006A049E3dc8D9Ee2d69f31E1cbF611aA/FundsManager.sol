/*
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./UniversalERC20.sol";

abstract contract FundsManager is Ownable {
    using UniversalERC20 for IERC20;

    /**
     * @dev Withdraw funds by owner
     * @param token Token address
     * @param amount The amount of token to withdraw
     **/
    function withdrawFunds(IERC20 token, uint256 amount) public onlyOwner {
        token.universalTransfer(owner(), amount);
    }

    /**
     * @dev Withdraw all funds by owner
     * @param tokens Token addresses array
     **/
    function withdrawAllFunds(IERC20[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            token.universalTransfer(
                owner(),
                token.universalBalanceOf(address(this))
            );
        }
    }
}
