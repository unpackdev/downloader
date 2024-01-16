// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.16;

library TestContractAccessControl {
    bytes32 public constant ROLE_DEPLOY_ADMIN = keccak256("ROLE_DEPLOY_ADMIN");
    bytes32 public constant ROLE_SIGNER_ADMIN = keccak256("ROLE_SIGNER_ADMIN");
    bytes32 public constant ROLE_TREASURY_ADMIN = keccak256("ROLE_TREASURY_ADMIN");
}
