// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Spec.sol";
import "./UpgradeableAccessControl.sol";
import "./Transfers.sol";

/**
 * @title Protocol Fee Distributor V1
 *
 * @notice Accepts protocol fees from the bonding curve contracts and distributes them
 *      later to the list of recipients via the admin-push mechanism
 *
 * @notice The factory manages protocol fees of the deployed TradeableShares contract:
 *      deployed contracts usually follow the protocol fees set on the factory
 */
contract ProtocolFeeDistributorV1 is UpgradeableAccessControl {
	// recipient details
	struct RecipientDetails {
		address payable recipient;
		uint32 allocationPercent;
	}

	// list of recipients
	RecipientDetails[] private recipients;

	// ERC20 payment token address
	ERC20 private /*immutable*/ paymentToken;

	// max number of recipients allowed
	uint8 public MAX_RECIPIENTS_ALLOWED;

	/**
	 * @notice Recipient list manager having role can add/update recipient details
	 *
	 * @dev Role ROLE_RECIPIENT_LIST_MANAGER manager to add/update recipient details
	 */
	uint32 public constant ROLE_RECIPIENT_LIST_MANAGER = 0x0001_0000;

	/**
	 * @notice Distribution manager having role can distributor protocol fees
	 *      to registered recipients
	 *
	 * @dev Role ROLE_DISTRIBUTION_MANAGER manager to distribute ETH/ERC20 to recipients
	 */
	uint32 public constant ROLE_DISTRIBUTION_MANAGER = 0x0002_0000;

	/**
	 * @dev Fired in receive()
	 *
	 * @param from address of user/contract who has sent Ether
	 * @param amount amount of ETH received
	 */
	event ETHReceived(address indexed from, uint256 amount);

	/**
	 * @dev Fired in distributeETH()
	 *
	 * @param recipient recipient address
	 * @param amount amount of ETH transferred
	 */
	event ETHSent(address indexed recipient, uint256 amount);

	/**
	 * @dev Fired in distributeERC20()
	 *
	 * @param paymentToken ERC20 payment token address
	 * @param recipient recipient address
	 * @param amount amount of ERC20 payment token transferred
	 */
	event ERC20Sent(address indexed paymentToken, address indexed recipient, uint256 amount);

	/**
	 * @dev Fired in updateRecipientsList()
	 *
	 * @param recipient recipient address
	 * @param allocation allocated in percentage with 4 decimal precision
	 */
	event RecipientsListUpdated(address indexed recipient, uint32 allocation);

	/**
	 * @dev "Constructor replacement" for a smart contract with a delayed initialization (post-deployment initialization)
	 *
	 * @param _paymentToken ERC20 payment token address
	 */
	function postConstruct(address _paymentToken) public virtual initializer {
		// execute parent initializer
		_postConstruct(msg.sender);

		require(_paymentToken != address(0), "zero address");

		paymentToken = ERC20(_paymentToken);
		MAX_RECIPIENTS_ALLOWED = 5; // max 5 recipients admin can add
	}

	/**
	 * @notice ERC20 payment token distributor is bound to
	 *
	 * @return ERC20 payment token
	 */
	function getPaymentToken() public view returns(ERC20) {
		return paymentToken;
	}

	// Function to receive Ether. msg.data must be empty
	receive() external payable virtual {
		// emit an event
		emit ETHReceived(msg.sender, msg.value);
	}

	/**
	 * @notice distribute Ether to all added recipients
	 *
	 * @dev distributes Ether to the recipients based on allocation of each recipient.
	 *
	 * @dev Restricted access function which can only accessable to address having
	 *      ROLE_DISTRIBUTION_MANAGER role.
	 */
	function distributeETH() public payable {
		// verify the access permission
		require(isSenderInRole(ROLE_DISTRIBUTION_MANAGER), "access denied");
		// verify whether contract has having enough balance to distribute
		require(address(this).balance > 0, "nothing to distribute");
		// verify the recipients list is not empty
		require(recipients.length > 0, "recipients list is empty");

		uint256 amount = address(this).balance;
		uint256 allocatedAmount;
		for(uint8 i = 0; i < recipients.length; i++) {
			allocatedAmount = amount * recipients[i].allocationPercent / 1e6;

			if(allocatedAmount > 0) {
				// transfer the ETH to the recipient
				Transfers.transfer(recipients[i].recipient, allocatedAmount);
				// emit an event
				emit ETHSent(recipients[i].recipient, allocatedAmount);
			}
		}
	}

	/**
	 * @notice distribute ERC20 token to all added recipients
	 *
	 * @dev distributes ERC20 token to the recipients based on allocation of each recipient.
	 *
	 * @dev Restricted access function which can only accessible to address having
	 *      ROLE_DISTRIBUTION_MANAGER role
	 */
	function distributeERC20() public {
		// verify the access permission
		require(isSenderInRole(ROLE_DISTRIBUTION_MANAGER), "access denied");
		// verify whether contract has having enough value to distribute
		require(paymentToken.balanceOf(address(this)) > 0, "nothing to distribute");
		// verify recipients list is not empty
		require(recipients.length > 0, "recipients list is empty");

		uint256 amount = paymentToken.balanceOf(address(this));
		uint256 allocatedAmount;
		for(uint8 i = 0; i < recipients.length; i++) {
			allocatedAmount = amount * recipients[i].allocationPercent / 1e6;

			if(allocatedAmount > 0) {
				require(paymentToken.transfer(recipients[i].recipient, allocatedAmount));
				// emit an event
				emit ERC20Sent(address(paymentToken), recipients[i].recipient, allocatedAmount);
			}
		}
	}

	/**
	 * @notice Add recipient address and allocation for each recipient
	 *
	 * @dev Restricted access function which can only accessible to address having
	 *      ROLE_RECIPIENT_LIST_MANAGER role.
	 *
	 * @dev total recipient allocation of all recipients in the list must be 100%,
	 *      else transaction will be reverted
	 *
	 * @param _recipients array of the recipients containing addresses and allocations
	 */
	function updateRecipientsList(RecipientDetails[] calldata _recipients) public {
		// verify the access permission
		require(isSenderInRole(ROLE_RECIPIENT_LIST_MANAGER), "access denied");
		// input validations
		require(_recipients.length > 0, "recipients list is empty");
		require(_recipients.length <= MAX_RECIPIENTS_ALLOWED, "recipients list is too big");

		// delete old recipients list
		delete recipients;

		uint256 totalAllocation;
		for(uint8 i = 0; i < _recipients.length; i++){
			require(_recipients[i].recipient != address(0), "zero recipient");

			totalAllocation += _recipients[i].allocationPercent;
			recipients.push(_recipients[i]);

			// emit an event
			emit RecipientsListUpdated(_recipients[i].recipient, _recipients[i].allocationPercent);
		}

		require(totalAllocation == 1e6, "totalAllocation must be 100%");
	}

	/**
	 * @notice Number of recipients added to the contract
	 *      `getRecipient(i)` can be used to iterate the list, 0 <= i < getRecipientsLength()
	 *
	 * @return total number of recipients
	 */
	function getRecipientsLength() public view returns(uint8) {
		return uint8(recipients.length);
	}

	/**
	 * @notice Reads an element from the list of recipients
	 *
	 * @param i zero-based index of the recipient
	 * @return recipient as RecipientDetails
	 */
	function getRecipient(uint256 i) public view returns(RecipientDetails memory) {
		return recipients[i];
	}

	/**
	 * @notice Returns the entire recipients list
	 *
	 * @return RecipientDetails[] recipients list array
	 */
	function getRecipients() public view returns(RecipientDetails[] memory) {
		return recipients;
	}
}
