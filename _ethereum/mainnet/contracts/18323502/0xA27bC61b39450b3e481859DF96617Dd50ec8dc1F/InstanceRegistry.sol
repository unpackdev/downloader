// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ITornadoInstance.sol";
import "./PGRouter.sol";

contract InstanceRegistry {
  using SafeERC20 for IERC20;

  enum InstanceState {
    DISABLED,
    ENABLED, // is enabled but mining is disabled
    MINABLE // is enabled and mining is enabled
  }

  struct Instance {
    bool isERC20;
    IERC20 token;
    InstanceState state;
    // the fee of the uniswap pool which will be used to get a TWAP
    uint24 uniswapPoolSwappingFee;
    // the fee the protocol takes from relayer, it should be multiplied by PROTOCOL_FEE_DIVIDER from FeeManager.sol
    uint32 protocolFeePercentage;
    uint256 maxDepositAmount;
  }

  struct TornadoConfig {
    ITornadoInstance addr;
    Instance instance;
  }
  uint256 public MAX_FEE = 30;
  address public governance;
  PGRouter public router;

  mapping(ITornadoInstance => Instance) public instances;
  ITornadoInstance[] public instanceIds;

  event InstanceStateUpdated(ITornadoInstance indexed instance, InstanceState state);
  event RouterRegistered(address pgRouter);
  event NewGovernanceAddressUpdated(address newGovernanceAddress);

  modifier onlyGovernance() {
    require(msg.sender == governance, "Not authorized");
    _;
  }

  constructor(address _governance) {
    governance = _governance;
  }

  /**
   * @dev initialise a set of tornado instances.
   */
  function initInstances(TornadoConfig[] memory _instances) external onlyGovernance {
    for (uint256 i = 0; i < _instances.length; i++) {
      _updateInstance(_instances[i]);
      instanceIds.push(_instances[i].addr);
    }
  }

  /**
   * @dev Update an instance state.
   */
  function updateInstanceState(ITornadoInstance _addr, InstanceState _state) external virtual onlyGovernance {
    Instance storage _instance = instances[_addr];
    _instance.state = _state;
    emit InstanceStateUpdated(_addr, _state);
  }

  /**
   * @dev Add or update an instance.
   */
  function updateInstance(TornadoConfig calldata _tornadoConf) external virtual onlyGovernance {
    require(_tornadoConf.instance.state != InstanceState.DISABLED, "Use removeInstance() for remove");

    Instance memory _inst = instances[_tornadoConf.addr];
    if (_inst.state == InstanceState.DISABLED && address(_inst.token) == address(0) && _inst.maxDepositAmount == 0) {
      // make sure it's a new instance.
      instanceIds.push(_tornadoConf.addr);
    }
    _updateInstance(_tornadoConf);
  }

  /**
   * @dev Remove an instance.
   * @param _instanceId The instance id in `instanceIds` mapping to remove.
   */
  function removeInstance(uint256 _instanceId) external virtual onlyGovernance {
    ITornadoInstance _instance = instanceIds[_instanceId];
    (bool isERC20, IERC20 token) = (instances[_instance].isERC20, instances[_instance].token);

    if (isERC20) {
      uint256 allowance = token.allowance(address(router), address(_instance));
      if (allowance != 0) {
        router.approveExactToken(token, address(_instance), 0);
      }
    }

    delete instances[_instance];
    instanceIds[_instanceId] = instanceIds[instanceIds.length - 1];
    instanceIds.pop();
    emit InstanceStateUpdated(_instance, InstanceState.DISABLED);
  }

  /**
   * @notice This function should allow governance to set a new protocol fee for relayers
   * @param instance the to update
   * @param newFee the new fee to use
   * */
  function setProtocolFee(ITornadoInstance instance, uint32 newFee) external onlyGovernance {
    require(address(instance) != address(0), "Empty Instance.");
    require(address(instances[instance].token) != address(0), "Instance Token is Empty.");
    require(newFee <= MAX_FEE, "NewFee exceed MaxFee.");

    instances[instance].protocolFeePercentage = newFee;
  }

  /**
   * @notice This function should allow governance to set a new tornado proxy address
   * @param routerAddress address of the new proxy
   * */
  function setPGRouter(address routerAddress) external onlyGovernance {
    router = PGRouter(routerAddress);
    emit RouterRegistered(routerAddress);
  }

  function _updateInstance(TornadoConfig memory _tornadoConf) internal virtual {
    instances[_tornadoConf.addr] = _tornadoConf.instance;

    if (_tornadoConf.instance.isERC20) {
      IERC20 token = IERC20(_tornadoConf.addr.token());
      require(token == _tornadoConf.instance.token, "Incorrect token");
      uint256 allowance = token.allowance(address(router), address(_tornadoConf.addr));

      if (allowance == 0) {
        router.approveExactToken(token, address(_tornadoConf.addr), type(uint256).max);
      }
    }
    emit InstanceStateUpdated(_tornadoConf.addr, _tornadoConf.instance.state);
  }

  /**
   * @dev Returns all instance configs
   */
  function getAllInstances() public view returns (TornadoConfig[] memory result) {
    result = new TornadoConfig[](instanceIds.length);
    for (uint256 i = 0; i < instanceIds.length; i++) {
      ITornadoInstance _instance = instanceIds[i];
      result[i] = TornadoConfig({ addr: _instance, instance: instances[_instance] });
    }
  }

  /**
   * @notice Set new governance address.
   * @param _govAddr new governance address
   */
  function setNewGovernance(address _govAddr) external onlyGovernance {
    require(_govAddr != address(0), "Empty governance address.");
    governance = _govAddr;
    emit NewGovernanceAddressUpdated(_govAddr);
  }

  /**
   * @dev Returns all instance addresses
   */
  function getAllInstanceAddresses() public view returns (ITornadoInstance[] memory result) {
    result = new ITornadoInstance[](instanceIds.length);
    for (uint256 i = 0; i < instanceIds.length; i++) {
      result[i] = instanceIds[i];
    }
  }

  /**
   * @notice get erc20 tornado instance token
   * @param instance the interface (contract) key to the instance data
   */
  function getPoolToken(ITornadoInstance instance) external view returns (address) {
    return address(instances[instance].token);
  }
}
