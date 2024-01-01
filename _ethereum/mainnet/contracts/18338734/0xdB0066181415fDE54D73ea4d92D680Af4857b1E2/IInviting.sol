// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/**
 * @title Inviting Interface
 * @author BEBE-TEAM
 * @notice Interface of the Inviting
 */
abstract contract IInviting {
    mapping(address => address) public userInviter;
}
