// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AccessControlUpgradeable.sol";
import "./RoleConstantsUpgradeable.sol";
import "./INeatToken.sol";
import "./IVestingEscrow.sol";
import "./IProtocolSettings.sol";
import "./ProtocolTreasuryStorageUpgradeable.sol";

/**
 * @title ProtocolTreasuryOperationsUpgradeable
 * @author NeatFi
 * @notice This contract holds the operations with the Treasury
 *         of the NeatFi Protocol, including Neat token vesting,
 *         locking and protocol fee yield claiming.
 */
contract ProtocolTreasuryOperationsUpgradeable is
    AccessControlUpgradeable,
    RoleConstantsUpgradeable,
    ProtocolTreasuryStorageUpgradeable
{
    /**
     * @dev An internal function to update the address of the
     *      current implementation of the NeatFi vesting escrow contract.
     * @param newVestingEscrow - The address of a new implementation for the
     *                           Vesting Escrow contract.
     */
    function _updateVestingEscrowAddress(address newVestingEscrow) internal {
        vestingEscrowAddress = newVestingEscrow;
    }

    /**
     * @dev An internal function to update the address of the
     *      current implementation of the NeatFi protocol settings contract.
     * @param newProtocolSettings - The address of a new implementation for the
     *                           Protocol Settings contract.
     */
    function _updateProtocolSettingsAddress(address newProtocolSettings)
        internal
    {
        protocolSettingsAddress = newProtocolSettings;
    }

    /**
     * @dev Retrieves the balance of the protocol treasury in native tokens
     *      i.e. Eth for Ethereum.
     */
    function _getBalance() internal view returns (uint256 contractBalance) {
        return address(this).balance;
    }

    /**
     * @dev Retrieves the Neat token balance of the Treasury.
     */
    function _getNeatTokenBalance()
        internal
        returns (uint256 neatTokenBalance)
    {
        return INeatToken(neatTokenAddress).balanceOf(address(this));
    }

    /** Protocol Fee Distribution & Neat Locking */

    /**
     * @dev An internal function to generate the hash of a Locker.
     * @param locker - The Locker struct.
     * @return lockerHash - The generated hash of the Locker.
     */
    function _hashLocker(Locker memory locker)
        internal
        pure
        returns (bytes32 lockerHash)
    {
        return
            keccak256(
                abi.encode(
                    LOCKER_TYPEHASH,
                    locker.tokenHolder,
                    locker.lockedTokenAmount,
                    locker.lockedAt,
                    locker.availableToUnlockAt,
                    locker.lockerStatus
                )
            );
    }

    /**
     * @notice An internal function to adjust the status of expired Lockers.
     * @dev This is called in every major Locker-related status changing
     *      functions to ensure maximum synchronization.
     * @param tokenHolder - The address of the creator of Lockers.
     */
    function _adjustLockerStatuses(address tokenHolder) internal {
        bytes32[] storage _lockersByAddress = lockersByAddress[tokenHolder];

        for (uint256 i = 0; i < _lockersByAddress.length; i++) {
            if (
                lockerInfo[_lockersByAddress[i]].availableToUnlockAt <
                block.timestamp &&
                lockerInfo[_lockersByAddress[i]].lockerStatus ==
                LockerStatus.ACTIVE
            ) {
                lockerInfo[_lockersByAddress[i]].lockerStatus = LockerStatus
                    .EXPIRED;
            }
        }
    }

    /**
     * @notice An internal function to lock Neat tokens on the treasury
     *         contract and receive yields of protocol fees. The size of
     *         the yield is proportional to the amount of locked tokens and
     *         is calculated in relation to the generated distribution Pool.
     *         Yield can only be distributed from a generated distribution Pool.
     *         Locker creation is not limited, and one address can have many
     *         Lockers with different amounts and maturity periods.
     * @dev This function transfers Neats from the token holder to the Treasury.
     *      Tokens remain "locked" on the balance of the Treasury contract until
     *      they are "unlocked".
     * @param tokenHolder - The address of the token holder.
     * @param tokenAmount - The amount of tokens to lock in this Locker. This number
     *                      must be a factor of 10, and the accepted values are:
     *                      - 100e18 (100 Neats)
     *                      - 1_000e18 (1,000 Neats)
     *                      - 10_000e18 (10,000 Neats)
     *                      - 100_000e18 (100,000 Neats)
     *                      - 1_000_000e18 (1,000,000 Neats)
     *                      - 10_000_000e18 (10,000,000 Neats)
     * @param lockPeriod - The number of days the tokens will be locked. The accepted
     *                     values are:
     *                     - 15 days (15 * 86400 in miliseconds)
     *                     - 30 days
     *                     - 60 days
     *                     - 90 days
     *                     - 180 days
     * @return lockerHash - The hash of the Locker.
     */
    function _lockNeatTokens(
        address tokenHolder,
        uint256 tokenAmount,
        uint256 lockPeriod
    ) internal returns (bytes32 lockerHash) {
        require(
            tokenAmount == 100e18 ||
                tokenAmount == 1_000e18 ||
                tokenAmount == 10_000e18 ||
                tokenAmount == 100_000e18 ||
                tokenAmount == 1_000_000e18 ||
                tokenAmount == 10_000_000e18,
            "ProtocolTreasuryOperationsUpgradeable::_lockNeatTokens: wrong amount of tokens to lock."
        );

        require(
            lockPeriod == 15 * DAY ||
                lockPeriod == 30 * DAY ||
                lockPeriod == 60 * DAY ||
                lockPeriod == 90 * DAY ||
                lockPeriod == 180 * DAY,
            "ProtocolTreasuryOperationsUpgradeable::_lockNeatTokens: wrong lock period."
        );

        _adjustLockerStatuses(tokenHolder);

        Locker memory locker = Locker(
            tokenHolder,
            tokenAmount,
            block.timestamp,
            block.timestamp + lockPeriod,
            // Locker status is set to ACTIVE immediately.
            LockerStatus.ACTIVE
        );

        lockerHash = _hashLocker(locker);

        lockerInfo[lockerHash] = locker;

        lockersByAddress[tokenHolder].push(lockerHash);

        lockedNeatsByAddress[tokenHolder] += tokenAmount;

        totalLockedNeats += tokenAmount;

        emit LockerCreated(locker, lockerHash);

        INeatToken(neatTokenAddress).transferFrom(
            tokenHolder,
            address(this),
            tokenAmount
        );

        return lockerHash;
    }

    /**
     * @notice An internal function to unlock Neat tokens.
     * @dev Transfers Neat tokens back to the token holder and
     *      sets the locker status to UNLOCKED, also nullifying the
     *      amount of tokens. Although this Locker data will still be
     *      available on chain, it's a dead record that doesn't do
     *      anything.
     * @param tokenHolder - The address of the token holder.
     * @param lockerHash - The hash of the Locker.
     */
    function _unlockNeatTokens(address tokenHolder, bytes32 lockerHash)
        internal
    {
        Locker storage locker = lockerInfo[lockerHash];

        require(
            block.timestamp >= locker.availableToUnlockAt,
            "ProtocolTreasuryOperationsUpgradeable::_unlockNeatTokens: can't unlock this locker yet."
        );

        require(
            locker.tokenHolder == tokenHolder,
            "ProtocolTreasuryOperationsUpgradeable::_unlockNeatTokens: token holder authentication fail."
        );

        lockedNeatsByAddress[tokenHolder] -= locker.lockedTokenAmount;
        totalLockedNeats -= locker.lockedTokenAmount;

        locker.lockedTokenAmount = 0;
        locker.lockerStatus = LockerStatus.UNLOCKED;

        _adjustLockerStatuses(tokenHolder);

        emit LockerUnlocked(locker, lockerHash);

        INeatToken(neatTokenAddress).transferFrom(
            address(this),
            tokenHolder,
            locker.lockedTokenAmount
        );
    }

    /**
     * @notice An internal function to extend the lock period of an ACTIVE
     *         Locker or renew the lock period for an EXPIRED Locker by also
     *         changing the status of that Locker to ACTIVE.
     * @param tokenHolder - The address of the token holder.
     * @param lockerHash - The hash of the Locker.
     * @param extensionPeriod - The new maturity period for this Locker. The accepted
     *                          values are:
     *                          - 15 days (15 * 86400 in miliseconds)
     *                          - 30 days
     *                          - 60 days
     *                          - 90 days
     *                          - 180 days
     */
    function _extendLockPeriod(
        address tokenHolder,
        bytes32 lockerHash,
        uint256 extensionPeriod
    ) internal {
        require(
            extensionPeriod >= 15 * DAY &&
                (extensionPeriod == 15 * DAY ||
                    extensionPeriod == 30 * DAY ||
                    extensionPeriod == 60 * DAY ||
                    extensionPeriod == 90 * DAY ||
                    extensionPeriod == 180 * DAY),
            "ProtocolTreasuryOperationsUpgradeable::_extendLockPeriod: wrong extension period."
        );

        Locker storage locker = lockerInfo[lockerHash];
        if (locker.availableToUnlockAt < block.timestamp) {
            locker.availableToUnlockAt = block.timestamp + extensionPeriod;
            locker.lockerStatus = LockerStatus.ACTIVE;
        } else {
            locker.availableToUnlockAt += extensionPeriod;
        }

        _adjustLockerStatuses(tokenHolder);
    }

    /**
     * @notice An internal function to retrive all Lockers of an address.
     * @param tokenHolder - The address of the Locker creator.
     * @return allLockersByAddress - Array containing Locker hashes.
     */
    function _getAllLockersByAddress(address tokenHolder)
        internal
        view
        returns (bytes32[] memory allLockersByAddress)
    {
        bytes32[] storage _lockersByAddress = lockersByAddress[tokenHolder];
        allLockersByAddress = _lockersByAddress;
        return allLockersByAddress;
    }

    /**
     * @notice An internal function to retrive all ACTIVE Lockers
     *         of an address.
     * @param tokenHolder - The address of the Locker creator.
     * @return An array containing ACTIVE Locker hashes.
     */
    function _getActiveLockersByAddress(address tokenHolder)
        internal
        view
        returns (bytes32[] memory)
    {
        bytes32[] storage _lockersByAddress = lockersByAddress[tokenHolder];

        bytes32[] memory tempActiveLockersArray = new bytes32[](
            _lockersByAddress.length
        );

        uint256 activeLockersArrayLength;

        for (uint256 i = 0; i < _lockersByAddress.length; i++) {
            if (
                lockerInfo[_lockersByAddress[i]].lockerStatus ==
                LockerStatus.ACTIVE
            ) {
                tempActiveLockersArray[i] = _lockersByAddress[i];
                activeLockersArrayLength++;
            }
        }

        bytes32[] memory allActiveLockersByAddress = new bytes32[](
            activeLockersArrayLength
        );

        for (uint256 i = 0; i < activeLockersArrayLength; i++) {
            allActiveLockersByAddress[i] = tempActiveLockersArray[i];
        }

        return allActiveLockersByAddress;
    }

    /**
     * @notice An internal function to claim the yield of protocol fees.
     *         Yield can be claimed only once per generated Pool. Any
     *         unclaimed Ether of the current pool will be added to the
     *         next generated Pool.
     * @dev Sums up the tokens in all ACTIVE Lockers of an address.
     *      The resulting number of tokens is used to calculate the share
     *      of Ether that the claimant will receive. Transfers yield in
     *      Ethers from the balance of the Treasury to the address of the
     *      claimant.
     * @param tokenHolder - Address of the claimant.
     */
    function _claimYield(address payable tokenHolder) internal {
        // Sanity check on first run, before pool generation.
        require(
            lastPoolGenerationTimestamp != 0,
            "ProtocolTreasuryOperationsUpgradeable::_claimYield: the first pool is not yet generated."
        );

        // Making sure no double-claimings for the same pool can happen.
        require(
            lastClaimedTimestamp[tokenHolder] <= lastPoolGenerationTimestamp,
            "ProtocolTreasuryOperationsUpgradeable::_claimYield: yield can not be claimed yet."
        );

        /* 
          Update Locker statuses to ensure only ACTIVE Lockers as of
          block.timestamp participate in share calculation.
         */
        _adjustLockerStatuses(tokenHolder);

        bytes32[] memory allActiveLockers = _getActiveLockersByAddress(
            tokenHolder
        );

        uint256 totalNeatsInActiveLockers;

        for (uint256 i = 0; i < allActiveLockers.length; i++) {
            totalNeatsInActiveLockers += lockerInfo[allActiveLockers[i]]
                .lockedTokenAmount;
        }

        uint256 yield = (totalNeatsInActiveLockers / totalLockedNeats) *
            currentFeeDistributionPool;

        /*
          Sanity check for the available balance, although it would be
          impossible to withdraw more than the current generated Pool. 
         */
        require(
            yield <= address(this).balance,
            "ProtocolTreasuryOperationsUpgradeable::_claimYield: not enough Eth on contract balance to distribute."
        );

        lastClaimedTimestamp[tokenHolder] = block.timestamp;

        bool sent = tokenHolder.send(yield);

        require(
            sent,
            "ProtocolTreasuryOperationsUpgradeable::_claimYield: failed to distribute fee yield."
        );

        emit YieldClaimed(tokenHolder, yield);
    }

    /**
     * @notice Internal function to retrive the Locker struct record
     *         by its hash.
     * @param lockerHash - The hash of the Locker.
     * @return locker - The Locker struct record.
     */
    function _getLocker(bytes32 lockerHash)
        internal
        view
        returns (Locker memory locker)
    {
        locker = lockerInfo[lockerHash];

        return locker;
    }

    /**
     * @notice Internal function to retrive the total number of
     *         locked tokens in all Lockers (ACTIVE and EXPIRED).
     * @param tokenHolder - The address of the Locker creator.
     * @return totalLockedNeats - The number of locked tokens.
     */
    function _getTotlaLockedNeats(address tokenHolder)
        internal
        view
        returns (uint256 totalLockedNeats)
    {
        return lockedNeatsByAddress[tokenHolder];
    }

    /** Distribution Pool Generation */

    /**
     * @notice An internal function to generate the current Pool
     *         protocol fee yields. Once generated, Neat token
     *         Locker creators are able to claim their share of the
     *         yield in Ethers.
     */
    function _generateDistributionPool() internal {
        uint256 protocolFeeDistributionNumerator = IProtocolSettings(
            protocolSettingsAddress
        ).getProtocolFeeDistributionNumerator();

        currentFeeDistributionPool +=
            (address(this).balance * protocolFeeDistributionNumerator) /
            1000;

        lastPoolGenerationTimestamp = block.timestamp;
    }

    /** Neat Token Vesting */

    /**
     * @dev Vests Neat tokens through the interface of Vesting Escrow contract.
     *      Transfers Neat tokens from the balance of the Treasury to the
     *      Vesting Escrow contract for further management.
     * @param vestee - The address of the vestee. This is not the address
     *                 of the Vesting Escrow contract, but the address of the
     *                 actuall vestee.
     * @param tokenAmount - The amount of Neat tokens to be vested.
     * @param cliffDays - The number of days of the vesting cliff (0 if no cliff).
     * @param initiallyAvailableTokens - The amount of Neat tokens the vestee can claim
     *                                   after the vesting creation.
     * @param periodMonths - The number of vesting months.
     */
    function _vestNeatTokens(
        address vestee,
        uint256 tokenAmount,
        uint256 cliffDays,
        uint256 initiallyAvailableTokens,
        uint256 periodMonths
    ) internal {
        require(
            _getNeatTokenBalance() >= tokenAmount,
            "ProtocolTreasuryOperationsUpgradeable::_vestNeatTokens: not enought Neat tokens in treasury."
        );

        // Transfers Neat tokens from the Treasury to Vesting Escrow.
        INeatToken(neatTokenAddress).transfer(
            vestingEscrowAddress,
            tokenAmount
        );

        // Vests the Neat tokens.
        IVestingEscrow(vestingEscrowAddress).vest(
            vestee,
            tokenAmount,
            cliffDays,
            initiallyAvailableTokens,
            periodMonths
        );
    }

    /** Funds Withdrawal */

    /**
     * @dev Withdraws Ether from this contract. Only available to a
     *      Protocol Treasurer.
     * @param withdrawalAddress - The target address of the withdrawal.
     */
    function _withdraw(
        address payable withdrawalAddress,
        uint256 withdrawalAmount
    ) internal {
        require(
            withdrawalAddress != address(0),
            "ProtocolTreasuryOperationsUpgradeable::_withdraw: withdrawal address can not be 0."
        );
        require(
            withdrawalAmount <= _getBalance() - currentFeeDistributionPool,
            "ProtocolTreasuryOperationsUpgradeable::_withdraw: incorrect withdrawal amount."
        );

        //slither-disable-next-line arbitrary-send
        bool sent = withdrawalAddress.send(withdrawalAmount);
        require(
            sent,
            "ProtocolTreasuryOperationsUpgradeable::_withdraw: failed to withdraw."
        );
    }

    /** Initializers */

    function __ProtocolTreasuryOperations_init(
        address _neatTokenAddress,
        address _vestingEscrowAddress,
        address _protocolSettingsAddress
    ) internal initializer {
        // Can be set only once
        neatTokenAddress = _neatTokenAddress;

        _updateVestingEscrowAddress(_vestingEscrowAddress);
        _updateProtocolSettingsAddress(_protocolSettingsAddress);

        __RoleConstants_init();
        __AccessControl_init();
        __ProtocolTreasuryStorage_init();
    }
}
