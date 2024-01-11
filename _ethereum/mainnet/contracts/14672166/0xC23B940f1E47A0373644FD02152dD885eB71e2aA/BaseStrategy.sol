// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./ILocker.sol";

contract BaseStrategy {
	/* ========== STATE VARIABLES ========== */
	ILocker locker;
	address public governance;
	address public rewardsReceiver;
	uint256 public veSDTFee;
	address public veSDTFeeProxy;
	uint256 public accumulatorFee;
	uint256 public claimerReward;
	uint256 public constant BASE_FEE = 10000;
	mapping(address => address) public gauges;
	mapping(address => bool) public vaults;
	mapping(address => uint256) public perfFee;
	mapping(address => address) public multiGauges;

	/* ========== EVENTS ========== */
	event Deposited(address _gauge, address _token, uint256 _amount);
	event Withdrawn(address _gauge, address _token, uint256 _amount);
	event Claimed(address _gauge, address _token, uint256 _amount);
	event VaultToggled(address _vault, bool _newState);
	event GaugeSet(address _gauge, address _token);

	/* ========== MODIFIERS ========== */
	modifier onlyGovernance() {
		require(msg.sender == governance, "!governance");
		_;
	}
	modifier onlyApprovedVault() {
		require(vaults[msg.sender], "!approved vault");
		_;
	}

	/* ========== CONSTRUCTOR ========== */
	constructor(
		ILocker _locker,
		address _governance,
		address _receiver
	) public {
		locker = _locker;
		governance = _governance;
		rewardsReceiver = _receiver;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	function deposit(address _token, uint256 _amount) external virtual onlyApprovedVault {}

	function withdraw(address _token, uint256 _amount) external virtual onlyApprovedVault {}

	function claim(address _gauge) external virtual {}

	function toggleVault(address _vault) external virtual onlyGovernance {}

	function setGauge(address _token, address _gauge) external virtual onlyGovernance {}

	function setMultiGauge(address _gauge, address _multiGauge) external virtual onlyGovernance {}
}
