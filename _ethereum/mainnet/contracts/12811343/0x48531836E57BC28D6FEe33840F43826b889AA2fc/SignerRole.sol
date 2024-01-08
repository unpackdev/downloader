// SPDX-License-Identifier: MIT
// this is copied from MintableOwnableToken
// https://etherscan.io/address/0x987a4d3edbe363bc351771bb8abdf2a332a19131#code
// modified by TART-tokyo

pragma solidity =0.8.6;

import "./iSignerRole.sol";
import "./AccessControlEnumerable.sol";

contract SignerRole is iSignerRole, AccessControlEnumerable {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SIGNER_ROLE, msg.sender);
    }

    modifier onlySigner() {
        require(isSigner(msg.sender), "msg.sender is not a signer");
        _;
    }

    function isSigner(address account) public override view returns (bool) {
        return hasRole(SIGNER_ROLE, account);
    }
}
