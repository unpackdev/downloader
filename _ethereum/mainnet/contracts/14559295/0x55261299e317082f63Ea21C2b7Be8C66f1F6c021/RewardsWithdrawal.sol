// SPDX-License-Identifier: ISC

pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Math.sol";

/**
 * @title Distribute Rewards to VoxoDeus Minters and Holders V1 / Ethereum v1
 * @custom:author Cypherverse LTD / VoxoDeus 2022.4 / Alfredo Lopez
 * @dev
 * @dev Note : Minters and Holders together are referred to as 'Users'
 */
contract RewardsWithdrawal is OwnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, Math {
    using SafeMathUpgradeable for uint256;
	using AddressUpgradeable for address;

	address private treasury;
	bytes32 public constant SENDER_ROLE = keccak256("SENDER_ROLE");  //	 Relayer Role

	/**
	 * @dev Event for when Rewards are sent to Users
	 * @param Users - Addresses of Users who received their Rewards
	 * @param Amounts - Amounts sent to Users (Balance minus Fee)
	 * @param EstimatedFee - Estimated Fee for the Bulk Transfer
	 * @param FeePerWithdrawal - Fee deducted from each User's Balance to obtain the Transfer Amount
	 */
	event RewardsSentToUsers(address[] Users, uint256[] Amounts, uint256 EstimatedFee, uint256 FeePerWithdrawal);

	/**
	 * @dev Event for when Rewards are sent to Treasury
	 * @param Amount - Amount of Expired Rewards and Balances
	 */
	event RewardsSentToTreasury(uint256 Amount);

	/**
	 * @dev Initialize Contract for the Upgradeable Transparent Pattern
	 * @param _treasuryAddress - Address of the Treasury
	 */
    function initialize(address _treasuryAddress, address _senderRoleAddress) initializer public {
		__Ownable_init();
		__Pausable_init();
		__ReentrancyGuard_init_unchained();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		treasury = _treasuryAddress;
		_setupRole(SENDER_ROLE, _senderRoleAddress);
    }

	/**
     * @dev Implementation / Instance of paused methods() in the ERC20 Standard.
     * @param status - Status boolean; True for paused, or False for unpaused. See {ERC20Pausable}.
     */
    function pause(bool status) public onlyOwner() {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

	 /**
	  * @dev Bulk Transfer the Rewards Withdrawals in Weekly Batches
	  * @param addresses - Addresses of Users whose Withdrawals make up this Bulk Transfer
	  * @param balanceAmounts - Rewards Balances requested for Withdrawal
	  * @param estimatedFee - Estimated Fee for sending the Bulk Transfer
	  */
	 function sendBatch(address[] calldata addresses, uint256[] calldata balanceAmounts, uint256 estimatedFee) external payable nonReentrant() whenNotPaused() onlyRole(SENDER_ROLE) {
		require(addresses.length == balanceAmounts.length, "VoxoDeus: addresses and balanceAmounts must be of equal length");
		uint256 sum = sumAll(addresses, balanceAmounts);
		// Verify the specified transfer amount `msg.value` matches sum of balance withdrawals
		// Tests whether the members of the batch are as expected
		require(msg.value == sum, "VoxoDeus : batch transfer amount must match sum of balance withdrawals.");
		uint256[] memory transferAmounts = new uint[](addresses.length);
		uint256 feePerWithdrawal = estimatedFee / addresses.length;

		 for (uint i = 0; i < addresses.length; i++) {
			uint256 transferAmount = balanceAmounts[i] >= feePerWithdrawal ? balanceAmounts[i] - feePerWithdrawal : 0;
			transferAmounts[i] += transferAmount;
			// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
			(bool success, ) = addresses[i].call{ value: transferAmount }("");
			require(success, "Address: unable to send value, recipient may have reverted");

		}
		emit RewardsSentToUsers(addresses, transferAmounts, estimatedFee, feePerWithdrawal);
	}

	/**
	 * @dev Send Expired Rewards and Balances to Treasury
	 */
	function sendToTreasury(uint256 transferAmount) external payable nonReentrant() whenNotPaused() onlyRole(SENDER_ROLE) {
		// Verify the specified transfer amount `msg.value` matches the 'transferAmount'
		// Tests whether someone manually calling the contract is a copy paste ninja
		require(transferAmount == msg.value, "VoxoDeus: transferAmount must match transaction value of Ether");
		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = treasury.call{ value: transferAmount }("");
		require(success, "VoxoDeus: unable to send value, recipient may have reverted");
		emit RewardsSentToTreasury(transferAmount);
	}

	/// @dev Helpers Methods

	/**
	 * @dev Sum values in 'amounts' Array based on indices in 'addresses' Array
	 * @return totalAmount - Sum of Rewards Balances included in the current batch
	 */
	function sumAll(address[] calldata addresses,uint256[] calldata amounts) public pure returns (uint256 totalAmount) {
       totalAmount = 0;
        for (uint i=0; i < addresses.length; i++) {
            totalAmount += amounts[i];
		}
    }
}
