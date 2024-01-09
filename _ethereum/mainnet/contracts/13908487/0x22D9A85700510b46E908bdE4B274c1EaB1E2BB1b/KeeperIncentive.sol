// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IACLRegistry.sol";
import "./IContractRegistry.sol";
import "./IStaking.sol";

contract KeeperIncentive {
  using SafeERC20 for IERC20;

  struct Incentive {
    uint256 reward; //pop reward for calling the function
    bool enabled;
    bool openToEveryone; //can everyone call the function to get the reward or only approved?
  }

  /* ========== STATE VARIABLES ========== */

  IContractRegistry public contractRegistry;

  uint256 public incentiveBudget;
  mapping(bytes32 => Incentive[]) public incentives;
  mapping(bytes32 => address) public controllerContracts;
  uint256 public burnRate;
  address internal immutable burnAddress = 0x000000000000000000000000000000000000dEaD; // Burn Address
  uint256 public requiredKeeperStake;

  /* ========== EVENTS ========== */

  event IncentiveCreated(bytes32 contractName, uint256 reward, bool openToEveryone);
  event IncentiveChanged(
    bytes32 contractName,
    uint256 oldReward,
    uint256 newReward,
    bool oldOpenToEveryone,
    bool newOpenToEveryone
  );
  event IncentiveFunded(uint256 amount);
  event ApprovalToggled(bytes32 contractName, bool openToEveryone);
  event IncentiveToggled(bytes32 contractName, bool enabled);
  event ControllerContractAdded(bytes32 contractName, address contractAddress);
  event Burned(uint256 amount);
  event BurnRateChanged(uint256 oldRate, uint256 newRate);
  event RequiredKeeperStakeChanged(uint256 oldRequirement, uint256 newRequirement);

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry _contractRegistry,
    uint256 _burnRate,
    uint256 _requiredKeeperStake
  ) {
    contractRegistry = _contractRegistry;
    burnRate = _burnRate; //25e16
    requiredKeeperStake = _requiredKeeperStake; // 2000 ether
  }

  /* ==========  MUTATIVE FUNCTIONS  ========== */

  function handleKeeperIncentive(
    bytes32 _contractName,
    uint8 _i,
    address _keeper
  ) external {
    require(msg.sender == controllerContracts[_contractName], "Can only be called by the controlling contract");

    Incentive memory incentive = incentives[_contractName][_i];

    if (!incentive.openToEveryone) {
      IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("Keeper"), _keeper);
      require(
        IStaking(contractRegistry.getContract(keccak256("PopLocker"))).balanceOf(_keeper) >= requiredKeeperStake,
        "not enough pop at stake"
      );
    }
    if (incentive.enabled && incentive.reward <= incentiveBudget && incentive.reward > 0) {
      incentiveBudget = incentiveBudget - incentive.reward;
      uint256 amountToBurn = (incentive.reward * burnRate) / 1e18;
      uint256 incentivePayout = incentive.reward - amountToBurn;
      IERC20(contractRegistry.getContract(keccak256("POP"))).safeTransfer(_keeper, incentivePayout);
      _burn(amountToBurn);
    }
  }

  /* ========== SETTER ========== */

  /**
   * @notice Create Incentives for keeper to call a function
   * @param _contractName Name of contract that uses ParticipationRewards in bytes32
   * @param _reward The amount in POP the Keeper receives for calling the function
   * @param _enabled Is this Incentive currently enabled?
   * @param _openToEveryone Can anyone call the function for rewards or only keeper?
   * @dev This function is only for creating unique incentives for future contracts
   * @dev Multiple functions can use the same incentive which can than be updated with one governance vote
   */
  function createIncentive(
    bytes32 _contractName,
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone
  ) public {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    incentives[_contractName].push(Incentive({reward: _reward, enabled: _enabled, openToEveryone: _openToEveryone}));
    emit IncentiveCreated(_contractName, _reward, _openToEveryone);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function updateIncentive(
    bytes32 _contractName,
    uint8 _i,
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone
  ) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    Incentive storage incentive = incentives[_contractName][_i];
    uint256 oldReward = incentive.reward;
    bool oldOpenToEveryone = incentive.openToEveryone;
    incentive.reward = _reward;
    incentive.enabled = _enabled;
    incentive.openToEveryone = _openToEveryone;
    emit IncentiveChanged(_contractName, oldReward, _reward, oldOpenToEveryone, _openToEveryone);
  }

  function toggleApproval(bytes32 _contractName, uint8 _i) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    Incentive storage incentive = incentives[_contractName][_i];
    incentive.openToEveryone = !incentive.openToEveryone;
    emit ApprovalToggled(_contractName, incentive.openToEveryone);
  }

  function toggleIncentive(bytes32 _contractName, uint8 _i) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    Incentive storage incentive = incentives[_contractName][_i];
    incentive.enabled = !incentive.enabled;
    emit IncentiveToggled(_contractName, incentive.enabled);
  }

  function fundIncentive(uint256 _amount) external {
    IERC20(contractRegistry.getContract(keccak256("POP"))).safeTransferFrom(msg.sender, address(this), _amount);
    incentiveBudget = incentiveBudget + _amount;
    emit IncentiveFunded(_amount);
  }

  /**
   * @notice In order to allow a contract to use ParticipationReward they need to be added as a controller contract
   * @param _contractName the name of the controller contract in bytes32
   * @param contract_ the address of the controller contract
   * @dev all critical functions to init/open vaults and add shares to them can only be called by controller contracts
   */
  function addControllerContract(bytes32 _contractName, address contract_) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    controllerContracts[_contractName] = contract_;
    emit ControllerContractAdded(_contractName, contract_);
  }

  /**
   * @notice Sets the current burn rate as a percentage of the incentive reward.
   * @param _burnRate Percentage in Mantissa. (1e14 = 1 Basis Point)
   */
  function updateBurnRate(uint256 _burnRate) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit BurnRateChanged(burnRate, _burnRate);
    burnRate = _burnRate;
  }

  function _burn(uint256 _amount) internal {
    IERC20(contractRegistry.getContract(keccak256("POP"))).transfer(burnAddress, _amount);
    emit Burned(_amount);
  }

  /**
   * @notice Sets the required amount of POP a keeper needs to have staked to handle incentivized functions.
   * @param _amount Amount of POP a keeper needs to stake
   */
  function updateRequiredKeeperStake(uint256 _amount) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit RequiredKeeperStakeChanged(requiredKeeperStake, _amount);
    requiredKeeperStake = _amount;
  }
}
