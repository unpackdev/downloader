// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./SdtDistributorEvents.sol";

contract SdtDistributor is ReentrancyGuardUpgradeable, AccessControlUpgradeable, SdtDistributorEvents {
	using SafeERC20 for IERC20;

	uint256 public timePeriod;

	/// @notice Role for governors only
	bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
	/// @notice Role for the guardian
	bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

	/// @notice Address of the SDT token given as a reward
	IERC20 public rewardToken;

	/// @notice Address of the token that will be deposited in masterchef
	IERC20 public masterchefToken;

	/// @notice Address of the masterchef
	IMasterchef public masterchef;

	/// @notice Address of the `GaugeController` contract
	IGaugeController public controller;

	/// @notice Address responsible for pulling rewards of type >= 2 gauges and distributing it to the
	/// associated contracts if there is not already an address delegated for this specific contract
	address public delegateGauge;

	/// @notice Whether SDT distribution through this contract is on or no
	bool public distributionsOn;

	/// @notice Maps the address of a type >= 2 gauge to a delegate address responsible
	/// for giving rewards to the actual gauge
	mapping(address => address) public delegateGauges;

	/// @notice Maps the address of a gauge to whether it was killed or not
	/// A gauge killed in this contract cannot receive any rewards
	mapping(address => bool) public killedGauges;

	/// @notice Maps the address of a gauge delegate to whether this delegate supports the `notifyReward` interface
	/// and is therefore built for automation
	mapping(address => bool) public isInterfaceKnown;

	/// @notice masterchef pid
	uint256 public masterchefPID;

	/// @notice timestamp of the last pull from masterchef
	uint256 public lastMasterchefPull;

	/// @notice Maps the timestapm of pull action to the amount of SDT that pulled
	mapping(uint256 => uint256) public pulls; // day => SDT amount

	/// @notice Maps the timestamp of last pull to the gauge addresses then keeps the data if particular gauge paid in the last pull
	mapping(uint256 => mapping(address => bool)) public isGaugePaid;

	/// @notice Initialize function
	/// @param _rewardToken token address used as reward
	/// @param _controller gauge controller to manage votes
	/// @param _masterchef masterchef address to redeem SDT
	/// @param _governor governor address
	/// @param _guardian guardian address
	/// @param _delegateGauge delegate gauge address
	function initialize(
		address _rewardToken,
		address _controller,
		address _masterchef,
		address _governor,
		address _guardian,
		address _delegateGauge
	) external initializer {
		require(
			_controller != address(0) && _rewardToken != address(0) && _guardian != address(0) && _governor != address(0),
			"0"
		);
		rewardToken = IERC20(_rewardToken);
		controller = IGaugeController(_controller);
		delegateGauge = _delegateGauge;
		masterchef = IMasterchef(_masterchef);
		masterchefToken = IERC20(address(new MasterchefMasterToken()));
		distributionsOn = false;
		timePeriod = 3600 * 24; // One day in seconds

		_setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ROLE);
		_setRoleAdmin(GUARDIAN_ROLE, GOVERNOR_ROLE);
		_setupRole(GUARDIAN_ROLE, _guardian);
		_setupRole(GOVERNOR_ROLE, _governor);
		_setupRole(GUARDIAN_ROLE, _governor);
	}

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() initializer {}

	/// @notice Initialize the masterchef depositing the master token
	/// @param _pid pool id to deposit the token
	function initializeMasterchef(uint256 _pid) external onlyRole(GOVERNOR_ROLE) {
		masterchefPID = _pid;
		masterchefToken.approve(address(masterchef), 1e18);
		masterchef.deposit(_pid, 1e18);
	}

	/// @notice Distribute SDT rewards to gauges
	/// @param gauges Array of gauges to distribute the rewards
	function distributeMulti(address[] memory gauges) external nonReentrant {
		require(distributionsOn == true, "not allowed");

		if (block.timestamp > lastMasterchefPull + timePeriod) {
			uint256 sdtBefore = rewardToken.balanceOf(address(this));
			_pullSDT();
			pulls[block.timestamp] = rewardToken.balanceOf(address(this)) - sdtBefore;
			lastMasterchefPull = block.timestamp;
		}

		for (uint256 i = 0; i < gauges.length; i++) {
			_distributeReward(gauges[i]);
		}
	}

	/// @notice Internal function used to distribute SDT rewards to a gauge
	/// @param gaugeAddr gauge address where distribute the rewards
	function _distributeReward(address gaugeAddr) internal {
		int128 gaugeType = controller.gauge_types(gaugeAddr);
		require(gaugeType >= 0 && !killedGauges[gaugeAddr], "Unrecognized or killed gauge");
		uint256 sdtBalance = pulls[lastMasterchefPull];
		bool isPaid = isGaugePaid[lastMasterchefPull][gaugeAddr];
		if (isPaid) {
			return;
		}

		uint256 gaugeRelativeWeight = controller.gauge_relative_weight(gaugeAddr);
		uint256 sdtDistributed = (sdtBalance * gaugeRelativeWeight) / 1e18;

		if (gaugeType == 1) {
			rewardToken.safeTransfer(gaugeAddr, sdtDistributed);
			IStakingRewards(gaugeAddr).notifyRewardAmount(sdtDistributed);
		} else if (gaugeType >= 2) {
			// If it is defined, we use the specific delegate attached to the gauge
			address delegate = delegateGauges[gaugeAddr];
			if (delegate == address(0)) {
				// If not, we check if a delegate common to all gauges with type >= 2 can be used
				delegate = delegateGauge;
			}
			if (delegate != address(0)) {
				// In the case where the gauge has a delegate (specific or not), then rewards are transferred to this gauge
				rewardToken.safeTransfer(delegate, sdtDistributed);
				// If this delegate supports a specific interface, then rewards sent are notified through this
				// interface
				if (isInterfaceKnown[delegate]) {
					ISdtMiddlemanGauge(delegate).notifyReward(gaugeAddr, sdtDistributed);
				}
			} else {
				rewardToken.safeTransfer(gaugeAddr, sdtDistributed);
			}
		} else {
			ILiquidityGauge(gaugeAddr).deposit_reward_token(address(rewardToken), sdtDistributed);
		}
		isGaugePaid[lastMasterchefPull][gaugeAddr] = true;
		emit RewardDistributed(gaugeAddr, sdtDistributed, lastMasterchefPull);
	}

	/// @notice Internal function to pull SDT from the MasterChef
	function _pullSDT() internal {
		masterchef.withdraw(masterchefPID, 0);
	}

	/// @notice Sets the distribution state (on/off)
	/// @param _state new distribution state
	function setDistribution(bool _state) external onlyRole(GOVERNOR_ROLE) {
		distributionsOn = _state;
	}

	/// @notice Sets a new gauge controller
	/// @param _controller Address of the new gauge controller
	function setGaugeController(address _controller) external onlyRole(GOVERNOR_ROLE) {
		require(_controller != address(0), "0");
		controller = IGaugeController(_controller);
		emit GaugeControllerUpdated(_controller);
	}

	/// @notice Sets a new delegate gauge for pulling rewards of a type >= 2 gauges or of all type >= 2 gauges
	/// @param gaugeAddr Gauge to change the delegate of
	/// @param _delegateGauge Address of the new gauge delegate related to `gaugeAddr`
	/// @param toggleInterface Whether we should toggle the fact that the `_delegateGauge` is built for automation or not
	/// @dev This function can be used to remove delegating or introduce the pulling of rewards to a given address
	/// @dev If `gaugeAddr` is the zero address, this function updates the delegate gauge common to all gauges with type >= 2
	/// @dev The `toggleInterface` parameter has been added for convenience to save one transaction when adding a gauge delegate
	/// which supports the `notifyReward` interface
	function setDelegateGauge(
		address gaugeAddr,
		address _delegateGauge,
		bool toggleInterface
	) external onlyRole(GOVERNOR_ROLE) {
		if (gaugeAddr != address(0)) {
			delegateGauges[gaugeAddr] = _delegateGauge;
		} else {
			delegateGauge = _delegateGauge;
		}
		emit DelegateGaugeUpdated(gaugeAddr, _delegateGauge);

		if (toggleInterface) {
			_toggleInterfaceKnown(_delegateGauge);
		}
	}

	/// @notice Toggles the status of a gauge to either killed or unkilled
	/// @param gaugeAddr Gauge to toggle the status of
	/// @dev It is impossible to kill a gauge in the `GaugeController` contract, for this reason killing of gauges
	/// takes place in the `SdtDistributor` contract
	/// @dev This means that people could vote for a gauge in the gauge controller contract but that rewards are not going
	/// to be distributed to it in the end: people would need to remove their weights on the gauge killed to end the diminution
	/// in rewards
	/// @dev In the case of a gauge being killed, this function resets the timestamps at which this gauge has been approved and
	/// disapproves the gauge to spend the token
	/// @dev It should be cautiously called by governance as it could result in less SDT overall rewards than initially planned
	/// if people do not remove their voting weights to the killed gauge
	function toggleGauge(address gaugeAddr) external onlyRole(GOVERNOR_ROLE) {
		bool gaugeKilledMem = killedGauges[gaugeAddr];
		if (!gaugeKilledMem) {
			rewardToken.safeApprove(gaugeAddr, 0);
		}
		killedGauges[gaugeAddr] = !gaugeKilledMem;
		emit GaugeToggled(gaugeAddr, !gaugeKilledMem);
	}

	/// @notice Notifies that the interface of a gauge delegate is known or has changed
	/// @param _delegateGauge Address of the gauge to change
	/// @dev Gauge delegates that are built for automation should be toggled
	function toggleInterfaceKnown(address _delegateGauge) external onlyRole(GUARDIAN_ROLE) {
		_toggleInterfaceKnown(_delegateGauge);
	}

	/// @notice Toggles the fact that a gauge delegate can be used for automation or not and therefore supports
	/// the `notifyReward` interface
	/// @param _delegateGauge Address of the gauge to change
	function _toggleInterfaceKnown(address _delegateGauge) internal {
		bool isInterfaceKnownMem = isInterfaceKnown[_delegateGauge];
		isInterfaceKnown[_delegateGauge] = !isInterfaceKnownMem;
		emit InterfaceKnownToggled(_delegateGauge, !isInterfaceKnownMem);
	}

	/// @notice Gives max approvement to the gauge
	/// @param gaugeAddr Address of the gauge
	function approveGauge(address gaugeAddr) external onlyRole(GOVERNOR_ROLE) {
		rewardToken.safeApprove(gaugeAddr, type(uint256).max);
	}

	/// @notice Set the time period to pull SDT from Masterchef
	/// @param _timePeriod new timePeriod value in seconds
	function setTimePeriod(uint256 _timePeriod) external onlyRole(GOVERNOR_ROLE) {
		timePeriod = _timePeriod;
	}

	/// @notice Withdraws ERC20 tokens that could accrue on this contract
	/// @param tokenAddress Address of the ERC20 token to withdraw
	/// @param to Address to transfer to
	/// @param amount Amount to transfer
	/// @dev Added to support recovering LP Rewards and other mistaken tokens
	/// from other systems to be distributed to holders
	/// @dev This function could also be used to recover SDT tokens in case the rate got smaller
	function recoverERC20(
		address tokenAddress,
		address to,
		uint256 amount
	) external onlyRole(GOVERNOR_ROLE) {
		IERC20(tokenAddress).safeTransfer(to, amount);
		emit Recovered(tokenAddress, to, amount);
	}
}
