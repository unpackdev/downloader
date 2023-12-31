// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import "./IAccount.sol";

interface IAccountFactory {
    function createAccount(uint256 salt) external returns (IAccount ret);

    function getAddress(uint256 salt) external view returns (address);
}
