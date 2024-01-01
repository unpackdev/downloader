// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.18;

import "./Common.sol";

interface IIssuance {
    error IssuanceReentrant();
    error IssuanceNoTokens();

    function issue(uint256 amount) external;

    function redeem(uint256 amount) external;
}
