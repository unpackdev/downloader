//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Address.sol";
import "./DonationErrors.sol";

/// @title Contract for accepting donations with attributes for the cause
contract Donation is Ownable {

	/// Event emitted when a donation is made to a cause
	/// @param donor The donor
	/// @param amount The amount of the donation
	/// @param cause The cause for the donation
	event DonatedToCause(
        address indexed donor,
        uint256 amount,
        string cause
    );

	/// Event emitted when the minimum and maximum donation limits are updated
	/// @param newMinimum The new mininimum allowable donation
	/// @param newMaximum The new maxinimum allowable donation
	event DonationLimitUpdated(
		uint256 newMinimum,
		uint256 newMaximum
	);

	/// Event emitted when the donations are withdrawn
	/// @param amount The amount withdrawn
	event DonationsWithdrawn(
		uint256 amount
	);

	/// Used to regulate the keys in the causesToDonations mapping
	uint256 private _mappingVersion;

	/// The maximum donation allowed by this contract
	/// @dev Trailing `_` allows us to pass Slither tests, while also communicating that this value is not public
    uint256 internal maximumDonation_ = 10 ether;

	/// The minimum donation allowed by this contract
	/// @dev Ensure this is high enough so that most of the transaction is not wasted on gas
    uint256 internal minimumDonation_ = 0.01 ether;

    /// The total of donations collected per cause
    /// @dev This value is internal in case subclasses wish to withdraw or otherwise access contract balances that are specific to donations
	mapping(bytes32 => uint256) internal causesToDonations_;

    /// Submits a donation to the contract
    /// @notice Donations outside of minimumDonation() and maximumDonation() are not allowed
	/// @param cause The cause for which to donate
    function donate(string calldata cause) external payable {
        if (msg.value == 0 || msg.value < minimumDonation_ || msg.value > maximumDonation_) revert InvalidDonationAmount();
		causesToDonations_[_keyForCause(cause)] += msg.value;
		emit DonatedToCause(msg.sender, msg.value, cause);
    }

	/// Returns the accumulated donations specific to a cause
	/// @notice This value may be reset by the owner
	/// @param cause The cause for which to display current donations
	function donationsForCause(string calldata cause) external view returns (uint256) {
		return causesToDonations_[_keyForCause(cause)];
	}

	/// Gets the maximum donation allowed by the contract
	/// @return The maximum allowable donation
	function maximumDonation() external view returns (uint256) {
		return maximumDonation_;
	}

	/// Gets the minimum donation allowed by the contract
	/// @return The minimum allowable donation
	function minimumDonation() external view returns (uint256) {
		return minimumDonation_;
	}

	/// Updates the minimum and maximum donation limits
	/// @param minimum The new minimum allowable donation
	/// @param maximum The new minimum allowable donation
	/// @dev Throws when maximum is less than minimum. You may set both to 0 to pause donations
	function updateDonationLimits(uint256 minimum, uint256 maximum) external onlyOwner {
		if (maximum < minimum) revert InvalidLimitsSpecified();
		maximumDonation_ = maximum;
		minimumDonation_ = minimum;
		emit DonationLimitUpdated(minimum, maximum);
	}

    /// Withdraws donations to the owner's wallet
    /// @dev This resets all mappings of causes to donations
    function withdraw() external onlyOwner {
		_mappingVersion++;
		emit DonationsWithdrawn(address(this).balance);
        Address.sendValue(payable(owner()), address(this).balance);
    }

	/// Returns the current mapping key for the specified cause
	/// @dev internal in case subclassing contracts wish to access the mapping
	/// @param cause The cause for which to obtain the mapping's key
	/// @return The `bytes32` key to be used in the `_causesToDonations` mapping
	function _keyForCause(string memory cause) internal view returns (bytes32) {
		bytes memory causeBytes = bytes(cause);
		if (causeBytes.length == 0 || causeBytes.length > 32) revert InvalidCause();
		return keccak256(abi.encodePacked(_mappingVersion, causeBytes));
	}
}
