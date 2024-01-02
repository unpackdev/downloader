// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IReferralProgramStorage.sol";

interface IReferralProgram is IReferralProgramStorage {
    /**
     * @dev event of register success
     * @param user  address
     * @param parent referrerOf of user
     */
    event RegisteredUser(address indexed user, address indexed parent);

    /**
     * @dev The event for set referrer by Admin.
     * @param referrer Address of a referrer added by Admin.
     */
    event SetReferrerByAdmin(address indexed referrer);

    /**
     * @dev The event for set referral by admin. The referral is set in accordance with her referrer.
     * @param referrer The address of a referrer.
     * @param referral The address of a referrer's referral.
     */
    event SetReferralByAdmin(address indexed referrer, address indexed referral);

    /**
     * @dev contract initializer
     * @param _registry The Registry contract address
     */
    function initialize(address _registry) external;

    /**
     * @dev Function to add new referral. Adds address that signed a hashed message as referrer
     * @param _referrerSignature Hash of MAGIC_MESSAGE signed by referrer
     */
    function register(bytes calldata _referrerSignature) external;

    /**
     *
     * @param referralProgramUnits Array of referrers with their referrals
     */
    function setReferrals(ReferralProgramUnit[] calldata referralProgramUnits) external;

    /**
     * @dev get list of referrers
     */
    function getReferrers() external view returns (address[] memory);

    /**
     * @dev Gets referrals array of particular referrer
     * @param _referrer The address of a referrer
     */
    function getReferralsOf(address _referrer) external view returns (address[] memory);

    /**
     * @dev The amount of referrals for a particular referrer
     * @param _referrer The address of a referrer
     */
    function getReferralsOfLength(address _referrer) external view returns (uint256);
}
