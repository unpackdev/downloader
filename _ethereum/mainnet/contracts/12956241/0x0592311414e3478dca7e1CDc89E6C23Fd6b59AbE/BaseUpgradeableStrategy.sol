pragma solidity 0.7.3;

import "./Initializable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "./ControllableInit.sol";
import "./IController.sol";

contract BaseUpgradeableStrategy is ControllableInit, BaseUpgradeableStrategyStorage {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  modifier restricted() {
    require(msg.sender == vault() || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor() public {
  }

  function initializeBaseUpgradeableStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _slpRewardPool,
    address _slpRewardToken,
    address _onxOnxFarmRewardPool,
    address _onxStakingRewardPool,
    bool _sell,
    uint256 _sellFloor,
    uint256 _implementationChangeDelay
  ) public initializer {
    ControllableInit.initializeControllableInit(
      _storage
    );
    BaseUpgradeableStrategyStorage.initializeBaseUpgradeableStrategyStorage();

    _setUnderlying(_underlying);
    _setVault(_vault);
    _setSLPRewardPool(_slpRewardPool);
    _setSLPRewardToken(_slpRewardToken);
    _setOnxFarmRewardPool(_onxOnxFarmRewardPool);
    _setOnxStakingRewardPool(_onxStakingRewardPool);

    _setSell(_sell);
    _setSellFloor(_sellFloor);
    _setPausedInvesting(false);
  }
}
