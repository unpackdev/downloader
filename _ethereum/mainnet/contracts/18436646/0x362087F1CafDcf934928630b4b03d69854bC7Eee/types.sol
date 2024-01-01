// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct BeamDetails {
    address sender;
    address token;
    uint256 chainId;
    address chainToken;
    address chainRecipient;
    uint256 amount;
}
