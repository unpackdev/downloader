// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IHYFI_Referrals.sol";

/**
 * @title HYFI OfflineReservations smart contract
 * @dev The implementation of ofline reservations logic
 * which provides updating information for offline buyers
 * - add - increment amount
 * - remove - decrement amount
 * - update - set amount
 * All the methods are available for Admin.
 * Admin can be EOA or the oracle contract if it is needed or other contract according to architecture
 * Contract provides the logic for single and batch changes
 * The length of array should be equal for batch updates.
 * The keys for the users array and for amounts array are appropriate
 */
contract HYFI_OfflineReservations is Initializable, AccessControlUpgradeable {
    mapping(address => uint256) reservations;
    address[] buyers;
    IHYFI_Referrals public referrals;

    /**
     * @dev modifier to check if the length of inout arrays is equal
     * @param users array of users addresses
     * @param amounts array of amounts (relative (for add/remove) or absolute for update)
     * @param referralCodes array of referral codes
     */
    modifier mArraysEqual(
        address[] memory users,
        uint256[] memory amounts,
        uint256[] memory referralCodes
    ) {
        require(
            users.length == amounts.length &&
                users.length == referralCodes.length,
            "Arrays length should be the same"
        );
        _;
    }

    /**
     * @dev event that should be emmited when amount of reserved tickets offline for the user is updated
     * @param user user's address
     * @param amount the additional amount of tickets reserved by user offline
     * @param referralCode referral code used by user for offline reservations
     */
    event OfflineReservationsAdded(
        address user,
        uint256 amount,
        uint256 referralCode
    );

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev set the new ReferralCalculator address
     * @param newReferral the new Referral address
     */
    function setReferralAddress(address newReferral)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        referrals = IHYFI_Referrals(newReferral);
    }

    /**
     * @dev increment the amount of reserved tickets for user
     * @param user user's address
     * @param amount the number of tickets to add
     * @param referralCode referral code used by user for offline reservations purchase
     */
    function addReservation(
        address user,
        uint256 amount,
        uint256 referralCode
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _addReservation(user, amount, referralCode);
    }

    /**
     * @dev increment the amount of reserved tickets for list of users
     * @param users array of users addresses for which we need changes
     * @param amounts array with the numbers of tickets to add for the users with appropriate key from users array
     * @param referralCodes array of referral codes
     */
    function addReservationsBatch(
        address[] memory users,
        uint256[] memory amounts,
        uint256[] memory referralCodes
    )
        external
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
        mArraysEqual(users, amounts, referralCodes)
    {
        for (uint256 i = 0; i < users.length; i++) {
            _addReservation(users[i], amounts[i], referralCodes[i]);
        }
    }

    /**
     * @dev get the list of buyers participated in offline reservations
     * @return array of users addresses who have reservations offline
     */
    function getBuyers() public view virtual returns (address[] memory) {
        return buyers;
    }

    /**
     * @dev get the amount of reserved tickets offline for specific user
     * @param user buyer address
     * @return amount of tickets bought offline
     */
    function getBuyerReservedAmount(address user)
        public
        view
        virtual
        returns (uint256)
    {
        return reservations[user];
    }

    /**
     * @dev processor for updating the final amount of reserved tickets for the user and emmiting event
     * @param user buyer address
     * @param amount increment amount of reserved tickets offline to update
     * @param referralCode referral code for which the amount of sold tickets should be updated
     */
    function _addReservation(
        address user,
        uint256 amount,
        uint256 referralCode
    ) private {
        if (reservations[user] == 0) {
            buyers.push(user);
        }
        if (amount > 0) {
            reservations[user] += amount;
            if (referralCode != 0) {
                referrals.updateAmountBoughtWithReferral(referralCode, amount);
            }
            emit OfflineReservationsAdded(user, amount, referralCode);
        }
    }
}
