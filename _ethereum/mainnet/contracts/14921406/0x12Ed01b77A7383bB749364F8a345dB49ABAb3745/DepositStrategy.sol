// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IBasePortfolio} from "IBasePortfolio.sol";

contract DepositStrategy {
    function deposit(IBasePortfolio portfolio, uint256 amount) public {
        portfolio.deposit(amount, msg.sender);
    }
}
