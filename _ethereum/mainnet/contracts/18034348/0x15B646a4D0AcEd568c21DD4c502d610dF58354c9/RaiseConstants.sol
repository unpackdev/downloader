// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

/// @notice Constants used in raise facet and raise encoder.
library RaiseConstants {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev EIP712 name
    bytes32 constant EIP712_NAME = keccak256(bytes("Fundraising:Raise"));
    /// @dev EIP712 versioning: "release:major:minor"
    bytes32 constant EIP712_VERSION = keccak256(bytes("1:1:0"));

    /// @dev Typehash for create raise by startup
    bytes32 constant STARTUP_CREATE_RAISE_TYPEHASH = keccak256("CreateRaiseRequest(bytes raise,bytes vested,bytes base)");
    /// @dev Typehash for set token by an early stage startup
    bytes32 constant STARTUP_SET_TOKEN_TYPEHASH = keccak256("SetTokenRequest(string raiseId,address token,bytes base)");
    /// @dev Typehash for investing into raise by investor
    bytes32 constant INVESTOR_INVEST_TYPEHASH = keccak256("InvestRequest(string raiseId,uint256 investment,uint256 maxTicketSize,bytes base)");
}
