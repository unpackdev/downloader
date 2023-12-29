// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IReferralRegistry {
    function referrerOf(address user) external view returns (address);

    function setReferrerProtocol(address _user, address _referrer) external;
}
