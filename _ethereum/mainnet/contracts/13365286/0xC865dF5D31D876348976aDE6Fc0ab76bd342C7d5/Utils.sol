// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./CTokens.sol";
import {IERC20} from  "../../vendor/openzeppelin/contracts/token/ERC20/IERC20.sol";

function getBalance(address token, address user) view returns (uint256) {
        if (token == ETH) {
            return user.balance;
        } else {
            return IERC20(token).balanceOf(user);
        }
    }