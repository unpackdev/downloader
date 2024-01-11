// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IBasePortfolio} from "IBasePortfolio.sol";

contract WithdrawStrategy {
    function withdraw(IBasePortfolio portfolio, uint256 shares) public {
        portfolio.withdraw(shares, msg.sender);
    }
}
