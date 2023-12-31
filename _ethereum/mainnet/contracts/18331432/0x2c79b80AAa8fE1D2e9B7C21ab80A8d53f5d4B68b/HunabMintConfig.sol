// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Hunab config for allowlist and public mint.
 */
contract HunabMintConfig {
    uint256 public constant MAX_AUTH_MINT_PER_WALLET = 3; // maximum mintable amount per allowlist address
    uint256 public constant MAX_AUTH_MINT = 600; // maximum mintable amount for the allowlist phase

    mapping(address => uint256) public authMinted;
    uint256 public totalAuthMinted;

    AuthMintConfig public authConfig;
    PublicMintConfig public publicConfig;

    // auth mint config
    struct AuthMintConfig {
        uint64 startTime;
        uint64 endTime;
        bytes32 verificationRoot;
    }

    // public mint config
    struct PublicMintConfig {
        uint64 startTime;
    }
}
