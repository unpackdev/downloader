// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IGaugeController.sol";
import "./ILiquidityGauge.sol";
import "./ISdtMiddlemanGauge.sol";
import "./IStakingRewards.sol";

import "./IMasterchef.sol";
import "./MasterchefMasterToken.sol";

import "./AccessControlUpgradeable.sol";

/// @title SdtDistributorEvents
/// @author StakeDAO Core Team
/// @notice All the events used in `SdtDistributor` contract
abstract contract SdtDistributorEvents {
	event DelegateGaugeUpdated(address indexed _gaugeAddr, address indexed _delegateGauge);
	event DistributionsToggled(bool _distributionsOn);
	event GaugeControllerUpdated(address indexed _controller);
	event GaugeToggled(address indexed gaugeAddr, bool newStatus);
	event InterfaceKnownToggled(address indexed _delegateGauge, bool _isInterfaceKnown);
	event RateUpdated(uint256 _newRate);
	event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);
	event RewardDistributed(address indexed gaugeAddr, uint256 sdtDistributed, uint256 lastMasterchefPull);
	event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
}
