// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Authority Whitelist smart contract interface
 * @notice this contract manages a whitelists for all the admins, borrowers and lenders
 */
interface IAuthority {
    function isWhitelistedBorrower(address a) external view returns (bool);

    function isWhitelistedLender(address a) external view returns (bool);

    function isAdmin(address a) external view returns (bool);
}
