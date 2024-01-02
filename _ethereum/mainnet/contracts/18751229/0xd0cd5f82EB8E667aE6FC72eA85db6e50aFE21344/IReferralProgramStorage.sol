// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IReferralProgramStorage {
    struct ReferralProgramUnit {
        address referrer;
        address[] referrals;
    }

    /**
     * @dev registry address
     */
    function registry() external view returns (address);

    /**
     * @dev referrer of address
     */
    function referrerOf(address) external view returns (address);

    /**
     * @dev referral Of address at index
     * @param _referrer address
     * @param _index index of referral
     * @return referral address
     */
    function referralsOf(address _referrer, uint256 _index) external view returns (address referral);
}
