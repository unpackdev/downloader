// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IBasePortfolio} from "IBasePortfolio.sol";

contract PortfolioClosedWithdrawStrategy {
    function withdraw(IBasePortfolio portfolio, uint256 shares) public {
        require(
            block.timestamp > portfolio.endDate(),
            "PortfolioClosedWithdrawStrategy: Cannot withdraw until portfolio end date has elapsed"
        );
        portfolio.withdraw(shares, msg.sender);
    }
}
