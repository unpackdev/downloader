// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PaymentSplitter.sol";

contract Payment is PaymentSplitter {
    constructor(address[] memory _team, uint256[] memory _teamShares) PaymentSplitter(_team, _teamShares) {}
}
