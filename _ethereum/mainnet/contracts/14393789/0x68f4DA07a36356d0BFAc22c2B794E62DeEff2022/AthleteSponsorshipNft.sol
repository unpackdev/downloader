// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IAthleteSponsorshipNftUpgradeable.sol";

contract AthleteSponsorshipNft is IAthleteSponsorshipNftUpgradeable {
    function initialize() public initializer {
        __IAthleteSponsorshipNft_init_unchained(
            "NAME by The Signing Day Collective",
            "SPNSR"
        );
    }
}
