// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

contract NftStandardProperties {

    // ---
    // Properties
    // ---

    uint256 public invocations = 0;
    uint256 public maxInvocations;
    uint256 public nextTokenId;
    uint256 public royaltyFeeBps;
}