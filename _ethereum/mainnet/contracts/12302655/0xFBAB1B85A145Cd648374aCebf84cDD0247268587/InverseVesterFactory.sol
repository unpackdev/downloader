// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./SafeERC20.sol";
import "./InverseVester.sol";

/**
 * @title Inverse token vesting factory contract
 * @author Inverse Finance
 * @notice Factory contract to create configurable vesting agreement
 */
contract InverseVesterFactory is Ownable {
    using SafeERC20 for IInv;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Emitted when vesting is created
    event VestingCreated(address recipient, address inverseVester, uint256 amount, uint16 vestingDuration);

    /// @dev Inverse finance governance timelock
    address public timelock;
    /// @dev Inverse finance treasury token
    address public immutable inv;
    /// @dev Registry of vesting agreements by recipient
    mapping(address => InverseVester[]) public inverseVestersByRecipient;
    /// @dev Registry of all recipients
    EnumerableSet.AddressSet private _allRecipients;

    constructor(address inv_, address timelock_) {
        require(inv_ != address(0) && timelock_ != address(0), "InverseVesterFactory:INVALID_ADDRESS");
        inv = inv_;
        timelock = timelock_;
        transferOwnership(timelock_);
    }

    /**
     * @notice Creates a new vesting agreement
     * @param recipient Recipient of the vesting agreement
     * @param vestingAmount Amount to vest
     * @param vestingDurationInDays Length of the vesting period express in days
     * @param vestingStartDelayInDays Delay between contract activation and vesting period start
     * @param reverseVesting True if tokens are owned but the recipient
     * @param interruptible True if governance can interrupt the agreement
     */
    function newInverseVester(
        address recipient,
        uint256 vestingAmount,
        uint16 vestingDurationInDays,
        uint16 vestingStartDelayInDays,
        bool reverseVesting,
        bool interruptible
    ) public onlyOwner {
        InverseVester inverseVester =
            new InverseVester(
                inv,
                timelock,
                vestingAmount,
                vestingDurationInDays,
                vestingStartDelayInDays,
                reverseVesting,
                interruptible,
                recipient
            );

        IInv(inv).safeTransferFrom(timelock, address(inverseVester), vestingAmount);

        inverseVestersByRecipient[recipient].push(inverseVester);
        _allRecipients.add(recipient);

        emit VestingCreated(recipient, address(inverseVester), vestingAmount, vestingDurationInDays);
    }

    /**
     * @notice Convenience function to create a new non interruptible vesting agreement
     * @param recipient Recipient of the vesting agreement
     * @param vestingAmount Amount to vest
     * @param vestingDurationInDays Length of the vesting period express in days
     * @param vestingStartDelayInDays Delay between contract activation and vesting period start
     * @param reverseVesting True if tokens are owned but the recipient
     */
    function newNonInterruptibleVestingAgreement(
        address recipient,
        uint256 vestingAmount,
        uint16 vestingDurationInDays,
        uint16 vestingStartDelayInDays,
        bool reverseVesting
    ) external {
        newInverseVester(
            recipient,
            vestingAmount,
            vestingDurationInDays,
            vestingStartDelayInDays,
            reverseVesting,
            false
        );
    }

    /**
     * @notice Convenience function to create a new interruptible vesting agreement
     * @param recipient Recipient of the vesting agreement
     * @param vestingAmount Amount to vest
     * @param vestingDurationInDays Length of the vesting period express in days
     * @param vestingStartDelayInDays Delay between contract activation and vesting period start
     * @param reverseVesting True if tokens are owned but the recipient
     */
    function newInterruptibleVestingAgreement(
        address recipient,
        uint256 vestingAmount,
        uint16 vestingDurationInDays,
        uint16 vestingStartDelayInDays,
        bool reverseVesting
    ) external {
        newInverseVester(
            recipient,
            vestingAmount,
            vestingDurationInDays,
            vestingStartDelayInDays,
            reverseVesting,
            true
        );
    }

    /**
     * @notice Convenience function to create a new standard salary agreement
     * @param recipient Recipient of the vesting agreement
     * @param vestingAmount Amount to vest
     * @param vestingDurationInDays Length of the vesting period express in days
     * @param vestingStartDelayInDays Delay between contract activation and vesting period start
     */
    function newSalaryAgreement(
        address recipient,
        uint256 vestingAmount,
        uint16 vestingDurationInDays,
        uint16 vestingStartDelayInDays
    ) external {
        newInverseVester(recipient, vestingAmount, vestingDurationInDays, vestingStartDelayInDays, false, true);
    }

    /**
     * @notice Returns all recipients of a vesting aggrement
     * @return recipients all recipients
     */
    function getAllRecipients() external view returns (address[] memory recipients) {
        uint256 length = _allRecipients.length();
        recipients = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            recipients[i] = _allRecipients.at(i);
        }
        return recipients;
    }

    /**
     * @notice Returns all vesting agreement for a recipient
     * @param recipient Recipient of the vesting agreements
     * @return all vesting agreements for recipient
     */
    function getInverseVestersByRecipient(address recipient) external view returns (InverseVester[] memory) {
        return inverseVestersByRecipient[recipient];
    }

    /**
     * @notice Replace timelock
     * @param newTimelock New timelock address
     */
    function setTimelock(address newTimelock) external onlyOwner {
        require(newTimelock != address(0), "InverseVesterFactory:INVALID_ADDRESS");
        timelock = newTimelock;
        transferOwnership(newTimelock);
    }
}
