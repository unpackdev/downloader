// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./ICToken.sol";

interface IComptroller {
    function checkMembership(address account_address, address tok_address) external view returns (bool);
    function enterMarkets(ICToken[] calldata cTokens) external returns (uint[] memory);
}
