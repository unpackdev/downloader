// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./UUPSUpgradeable.sol";
import "./ProtocolTreasuryOperationsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @title NeatFiProtocolTreasuryV1
 * @author NeatFi
 * @notice This contract implements the external facing functionality
 *         for the Protocol Treasury contract of NeatFi. This is the contract
 *         that is used to manage the protocol fees.
 */
contract NeatFiProtocolTreasuryV1 is
    UUPSUpgradeable,
    ProtocolTreasuryOperationsUpgradeable,
    ReentrancyGuardUpgradeable
{
    string internal name;
    string internal currentVersion;

    /** Administration */

    /**
     * @notice An external function to allow this contract to receive
     *         protocol fees in Ether.
     */
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /**
     * @notice An external function to update the address of the
     *      current implementation of the NeatFi vesting escrow contract.
     * @dev Can be executed by a protocol admin only.
     * @param newVestingEscrow - The address of a new implementation for the
     *                           Vesting Escrow contract.
     */
    function updateVestingEscrowAddress(address newVestingEscrow)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        _updateVestingEscrowAddress(newVestingEscrow);
    }

    /**
     * @notice An internal function to update the address of the
     *      current implementation of the NeatFi protocol settings contract.
     * @dev Can be executed by a protocol admin only.
     * @param newProtocolSettings - The address of a new implementation for the
     *                           Protocol Settings contract.
     */
    function updateProtocolSettingsAddress(address newProtocolSettings)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        _updateProtocolSettingsAddress(newProtocolSettings);
    }

    /**
     * @dev Sets the version for the current implementation of this contract.
     */
    function _setVersion(string memory newVersion) internal {
        currentVersion = newVersion;
    }

    /**
     * @dev Retrieves the balance of the protocol treasury.
     */
    function getBalance() public view returns (uint256 contractBalance) {
        return _getBalance();
    }

    /**
     * @dev Retrieves the Neat token balance of the Treasury.
     */
    function getNeatTokenBalance() external returns (uint256 neatTokenBalance) {
        return _getNeatTokenBalance();
    }

    /** Protocol Fee Distribution & Neat Locking */

    /**
     * @notice A public function to lock Neat tokens and receive yields
     *         of protocol fees in Ethers. More info can be found in the
     *         notes of the internal function.
     * @param tokenAmount - The number of Neat tokens to lock.
     * @param lockPeriod - The number of days to lock the tokens.
     */
    function lockNeatTokens(uint256 tokenAmount, uint256 lockPeriod)
        public
        nonReentrant
        returns (bytes32 lockerHash)
    {
        return _lockNeatTokens(_msgSender(), tokenAmount, lockPeriod);
    }

    /**
     * @notice Public function to unlock Neat tokens from a specific Locker.
     *         More info can be found in the notes of the internal function.
     * @param lockerHash - The hash of the Locker to unlock.
     */
    function unlockNeatTokens(bytes32 lockerHash) public nonReentrant {
        _unlockNeatTokens(_msgSender(), lockerHash);
    }

    /**
     * @notice Public function to extend the lock period of a specific Locker.
     *         More info can be found in the notes of the internal function.
     * @param lockerHash - The hash of the Locker.
     * @param extensionPeriod - The number of days to extend the Locker.
     */
    function extendLockPeriod(bytes32 lockerHash, uint256 extensionPeriod)
        public
        nonReentrant
    {
        _extendLockPeriod(_msgSender(), lockerHash, extensionPeriod);
    }

    /**
     * @notice Public function to retrive all Lockers of an address.
     * @return allLockersByAddress - Array containing Locker hashes.
     */
    function getAllLockersByAddress()
        public
        view
        returns (bytes32[] memory allLockersByAddress)
    {
        return _getAllLockersByAddress(_msgSender());
    }

    /**
     * @notice Public function to retrive all ACTIVE Lockers
     *         of an address.
     * @return An array containing ACTIVE Locker hashes.
     */
    function getActiveLockersByAddress()
        public
        view
        returns (bytes32[] memory)
    {
        return _getActiveLockersByAddress(_msgSender());
    }

    /**
     * @notice Public function to retrive the Locker struct record
     *         by its hash.
     * @param lockerHash - The hash of the Locker.
     * @return locker - The Locker struct record.
     */
    function getLocker(bytes32 lockerHash)
        public
        view
        returns (Locker memory locker)
    {
        return _getLocker(lockerHash);
    }

    /**
     * @notice Public function to retrive the total number of
     *         locked tokens in all Lockers (ACTIVE and EXPIRED).
     * @return totalLockedNeats - The number of locked tokens.
     */
    function getTotlaLockedNeats()
        public
        view
        returns (uint256 totalLockedNeats)
    {
        return _getTotlaLockedNeats(_msgSender());
    }

    /**
     * @notice Public function to claim yield of protocol fees
     *         from tokens in ACTIVE Lockers. More info can be
     *         found in the notes of the internal function.
     */
    function claimYield() public nonReentrant {
        _claimYield(payable(_msgSender()));
    }

    /** Distribution Pool Generation */

    /**
     * @notice External function to generate the current Pool
     *         protocol fee yields. More info in the docs of the
     *         internal function.
     * @dev Can be executed by a protocol treasurer only.
     */
    function generateDistributionPool()
        external
        nonReentrant
        onlyRole(PROTOCOL_TREASURER)
    {
        _generateDistributionPool();
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
    function vestNeatTokens(
        address vestee,
        uint256 tokenAmount,
        uint256 cliffDays,
        uint256 initiallyAvailableTokens,
        uint256 periodMonths
    ) external onlyRole(PROTOCOL_TREASURER) {
        _vestNeatTokens(
            vestee,
            tokenAmount,
            cliffDays,
            initiallyAvailableTokens,
            periodMonths
        );
    }

    /**
     * @dev Withdraws Ether from this contract. Only available to a
     *      Protocol Treasurer.
     * @param withdrawalAddress - The target address of the withdrawal.
     */
    function withdraw(
        address payable withdrawalAddress,
        uint256 withdrawalAmount
    ) external onlyRole(PROTOCOL_TREASURER) {
        _withdraw(withdrawalAddress, withdrawalAmount);
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(PROTOCOL_ADMIN)
    {}

    function initialize(
        address _neatTokenAddress,
        address _vestingEscrowAddress,
        address _protocolSettingsAddress
    ) public initializer onlyProxy {
        __UUPSUpgradeable_init();
        __ProtocolTreasuryOperations_init(
            _neatTokenAddress,
            _vestingEscrowAddress,
            _protocolSettingsAddress
        );
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        name = "NeatFi Treasury Contract";
        _setVersion("1.0.0");
    }
}
