// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IBasePortfolio} from "IBasePortfolio.sol";

contract NonUsOnlyDeposit {
    function deposit(
        IBasePortfolio portfolio,
        uint256 amount,
        bool iAmNotUSCitizen
    ) external {
        require(iAmNotUSCitizen, "NonUsOnlyDeposit: Sender cannot be US Citizen");
        portfolio.deposit(amount, msg.sender);
    }
}
