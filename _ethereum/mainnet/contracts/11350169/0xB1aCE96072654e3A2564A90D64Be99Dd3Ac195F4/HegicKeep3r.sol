// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./IHegic.sol";
import "./IHegicKeep3r.sol";
import "./IKeep3rV1Helper.sol";
import "./IUniswapV2SlidingOracle.sol";
import "./Governable.sol";
import "./CollectableDust.sol";

import "./Keep3rAbstract.sol";

contract HegicKeep3r is Governable, CollectableDust, Keep3r, IHegicKeep3r {
    using SafeMath for uint256;

    address public keep3rHelper;
    address public slidingOracle;
    address public ethOptions;
    address public wbtcOptions;

    uint256 public unlockGasCost;
    uint256 public unlockValueMultiplier;

    address public constant KP3R = address(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant WBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    constructor(
        address _keep3r,
        address _keep3rHelper,
        address _slidingOracle,
        address _ethOptions,
        address _wbtcOptions,
        uint256 _unlockGasCost,
        uint256 _unlockValueMultiplier
    ) public Governable(msg.sender) CollectableDust() Keep3r(_keep3r) {
        keep3rHelper = _keep3rHelper;
        slidingOracle = _slidingOracle;
        ethOptions = _ethOptions;
        wbtcOptions = _wbtcOptions;
        unlockGasCost = _unlockGasCost;
        unlockValueMultiplier = _unlockValueMultiplier;
    }

    // Getters
    function name() external pure override returns (string memory) {
        return "Hegic Keep3r";
    }

    function ethOptionsUnlockable(uint256[] calldata optionIDs) external override view returns (bool) {
        uint256 _ethTotalUnlock = this.ethTotalUnlock(optionIDs);

        // If _ethTotalUnlock is 0 that means that one of the options was
        // not in the correct state.
        if (_ethTotalUnlock == 0) {
            return false;
        }

        uint256 _ethPoolUsage = this.ethPoolUsage();
        uint256 _unlockValue = this.unlockValue(_ethTotalUnlock);
        uint256 _callCost = this.ethCallCost(optionIDs.length);
        uint256 _weightedUnlockValue = this.weightedUnlockValue(_ethPoolUsage, _unlockValue);

        return _callCost <= _weightedUnlockValue;
    }

    function wbtcOptionsUnlockable(uint256[] calldata optionIDs) external override view returns (bool) {
        uint256 _wbtcTotalUnlock = this.wbtcTotalUnlock(optionIDs);

        // If _wbtcTotalUnlock is 0 that means that one of the options was
        // not in the correct state.
        if (_wbtcTotalUnlock == 0) {
            return false;
        }

        uint256 _wbtcPoolUsage = this.wbtcPoolUsage();
        uint256 _unlockValue = this.unlockValue(_wbtcTotalUnlock);
        uint256 _callCost = this.wbtcCallCost(optionIDs.length);
        uint256 _weightedUnlockValue = this.weightedUnlockValue(_wbtcPoolUsage, _unlockValue);

        return _callCost <= _weightedUnlockValue;
    }

    // Keep3r actions
    function ethUnlockAll(uint256[] calldata optionIDs) external override paysKeeper {
        require(this.ethOptionsUnlockable(optionIDs));
        IHegicOptions(ethOptions).unlockAll(optionIDs);
    }

    function wbtcUnlockAll(uint256[] calldata optionIDs) external override paysKeeper {
      require(this.wbtcOptionsUnlockable(optionIDs));
      IHegicOptions(wbtcOptions).unlockAll(optionIDs);
    }

    // Helpers
    function weightedUnlockValue(uint256 poolUsage, uint256 unlockValue) external override view returns (uint256) {
        require(poolUsage <= 80);
        return poolUsage.mul(unlockValue).div(80);
    }

    function unlockValue(uint256 totalUnlock) external override view returns (uint256) {
        return totalUnlock.mul(unlockValueMultiplier).div(100);
    }

    function ethCallCost(uint256 optionsQty) external override view returns (uint256) {
        require(optionsQty > 0);

        uint256 kp3rCallCost = IKeep3rV1Helper(keep3rHelper).getQuoteLimit(optionsQty.mul(unlockGasCost));
        return IUniswapV2SlidingOracle(slidingOracle).current(KP3R, kp3rCallCost, WETH);
    }

    function wbtcCallCost(uint256 optionsQty) external override view returns (uint256) {
        uint256 _ethCallCost = this.ethCallCost(optionsQty);
        return IUniswapV2SlidingOracle(slidingOracle).current(WETH, _ethCallCost, WBTC);
    }

    function ethPoolUsage() external override view returns (uint256) {
        return _poolUsage(ethOptions);
    }

    function wbtcPoolUsage() external override view returns (uint256) {
        return _poolUsage(wbtcOptions);
    }

    function _poolUsage(address hegic) internal view returns (uint256) {
        address pool = IHegicOptions(hegic).pool();
        uint256 availableBalance = IHegicPool(pool).availableBalance();
        uint256 totalBalance = IHegicPool(pool).totalBalance();

        // Shouldn't happen
        if (totalBalance == 0) {
            return 0;
        }

        return uint256(100).sub(availableBalance.mul(100).div(totalBalance));
    }

    function ethTotalUnlock(uint256[] calldata optionIDs) external override view returns (uint256) {
        return _totalUnlock(ethOptions, optionIDs);
    }

    function wbtcTotalUnlock(uint256[] calldata optionIDs) external override view returns (uint256) {
        return _totalUnlock(wbtcOptions, optionIDs);
    }

    function _totalUnlock(address hegic, uint256[] calldata optionIDs) internal view returns (uint256) {
        uint256 len = optionIDs.length;
        uint256 totalUnlock = 0;

        for (uint256 i = 0; i < len; i++) {
            Option memory option = IHegicOptions(hegic).options(optionIDs[i]);

            // if one of the options is not active or not expired, do not continue
            if (option.state != State.Active || option.expiration >= block.timestamp) {
                return 0;
            }

            totalUnlock += option.lockedAmount;
            totalUnlock += option.premium;
        }

        return totalUnlock;
    }

    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Setters
    function setUnlockValueMultiplier(uint256 _unlockValueMultiplier) external override onlyGovernor {
        require(_unlockValueMultiplier > 0 && _unlockValueMultiplier < 100);
        unlockValueMultiplier = _unlockValueMultiplier;
        emit UnlockValueMultiplierSet(_unlockValueMultiplier);
    }

    function setUnlockGasCost(uint256 _unlockGasCost) external override onlyGovernor {
        unlockGasCost = _unlockGasCost;
        emit UnlockGasCostSet(_unlockGasCost);
    }

    function setKeep3r(address _keep3r) external override onlyGovernor {
        _setKeep3r(_keep3r);
        emit Keep3rSet(_keep3r);
    }

    function setKeep3rHelper(address _keep3rHelper) external override onlyGovernor {
        keep3rHelper = _keep3rHelper;
        emit Keep3rHelperSet(_keep3rHelper);
    }

    function setSlidingOracle(address _slidingOracle) external override onlyGovernor {
        slidingOracle = _slidingOracle;
        emit SlidingOracleSet(_slidingOracle);
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }
}
