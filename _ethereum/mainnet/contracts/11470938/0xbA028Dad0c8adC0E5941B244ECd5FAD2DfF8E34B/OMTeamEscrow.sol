// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./Escrow.sol";

contract OMTeamEscrow is Escrow {
    constructor(IERC20 token_) public Escrow(token_) {}
}
