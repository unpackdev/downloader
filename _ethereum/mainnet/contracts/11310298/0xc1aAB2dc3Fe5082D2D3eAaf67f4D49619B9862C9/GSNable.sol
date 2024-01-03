pragma solidity 0.6.6;

import "./IRelayRecipient.sol";
import "./GSNRecipient.sol";


/**
 * @author Simon Dosch
 * @title GSNable
 * @dev enables GSN capability by implementing GSNRecipient
 * Can be set to accept ALL, NONE or add a MODULE implementing restrictions
 */
contract GSNable is GSNRecipient {
	/**
	 * @dev Emitted when a new GSN mode is set
	 */
	event GSNModeSet(gsnMode);

	/**
	 * @dev Emitted when a new GSN module address is set
	 */
	event GSNModuleSet(IRelayRecipient);

	/**
	 * @dev Add access control by overriding this function!
	 * should return true if sender is authorized
	 */
	function _isGSNController() internal virtual view returns (bool) {
		this;
		return true;
	}

	/**
	 * @dev Address of the GSN MODULE implementing IRelayRecipient
	 */
	IRelayRecipient private _gsnModule = IRelayRecipient(address(0));

	/**
	 * @dev Modifier to make a function callable only when _isGSNController returns true
	 */
	modifier onlyGSNController() {
		require(_isGSNController(), "!GSN_CONTROLLER");
		_;
	}

	/**
	 * @dev doc in IRelayRecipient
	 */
	function acceptRelayedCall(
		address relay,
		address from,
		bytes calldata encodedFunction,
		uint256 transactionFee,
		uint256 gasPrice,
		uint256 gasLimit,
		uint256 nonce,
		bytes calldata approvalData,
		uint256 maxPossibleCharge
	) external override view returns (uint256, bytes memory) {
		if (_gsnMode == gsnMode.ALL) {
			return _approveRelayedCall();
		} else if (_gsnMode == gsnMode.MODULE) {
			return
				_gsnModule.acceptRelayedCall(
					relay,
					from,
					encodedFunction,
					transactionFee,
					gasPrice,
					gasLimit,
					nonce,
					approvalData,
					maxPossibleCharge
				);
		} else {
			return _rejectRelayedCall(0);
		}
	}

	/**
	 * @dev doc in IRelayRecipient
	 */
	function _preRelayedCall(bytes memory context)
		internal
		override
		returns (bytes32)
	{
		if (_gsnMode == gsnMode.MODULE) {
			return _gsnModule.preRelayedCall(context);
		}
	}

	/**
	 * @dev doc in IRelayRecipient
	 */
	function _postRelayedCall(
		bytes memory context,
		bool success,
		uint256 actualCharge,
		bytes32 preRetVal
	) internal override {
		if (_gsnMode == gsnMode.MODULE) {
			return
				_gsnModule.postRelayedCall(
					context,
					success,
					actualCharge,
					preRetVal
				);
		}
	}

	/**
	 * @dev Sets GSN mode to either ALL, NONE or MODULE
	 * @param mode ALL, NONE or MODULE
	 */
	function setGSNMode(gsnMode mode) public onlyGSNController {
		_gsnMode = gsnMode(mode);
		emit GSNModeSet(mode);
	}

	/**
	 * @dev Gets GSN mode
	 * @return gsnMode ALL, NONE or MODULE
	 */
	function getGSNMode() public view onlyGSNController returns (gsnMode) {
		return _gsnMode;
	}

	/**
	 * @dev Sets Module address for MODULE mode
	 * @param newGSNModule Address of new GSN module
	 */
	function setGSNModule(IRelayRecipient newGSNModule)
		public
		onlyGSNController
	{
		_gsnModule = newGSNModule;
		emit GSNModuleSet(newGSNModule);
	}

	/**
	 * @dev Upgrades the relay hub address
	 * @param newRelayHub Address of new relay hub
	 */
	function upgradeRelayHub(address newRelayHub) public onlyGSNController {
		_upgradeRelayHub(newRelayHub);
	}

	/**
	 * @dev Withdraws GSN deposits for this contract
	 * @param amount Amount to be withdrawn
	 * @param payee Address to sned the funds to
	 */
	function withdrawDeposits(uint256 amount, address payable payee)
		public
		onlyGSNController
	{
		_withdrawDeposits(amount, payee);
	}
}
