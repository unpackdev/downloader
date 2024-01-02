// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC165Upgradeable.sol";

import "./IReferralProgramStorage.sol";

abstract contract ReferralProgramStorage is IReferralProgramStorage, ERC165Upgradeable {
    address public override registry;
    mapping(address => address) public referrerOf; // referral => referrer
    mapping(address => address[]) public referralsOf; // referrer => referrals
    address[] public referrers; // list of all referrers
    mapping(address => bool) internal alreadyReferrer;
}
