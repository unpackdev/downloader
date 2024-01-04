// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./StrategyBase.sol";
import "./IVault.sol";
import "./IController.sol";
import "./ICurveFi.sol";
import "./ICurveGauge.sol";

/**
 * @dev Base strategy for one token on Curve.
 * Important tokens:
 * - want: The token managed by the vault, e.g. WBTC
 * - lp: The LP token when the want token is deposited into the target Curve swap, e.g. renCrv
 * - lpVault: The vault share token of lp vault, e.g. renCrvv
 */
abstract contract StrategyCurveBase is StrategyBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event SlippageUpdated(uint256 oldSlippage, uint256 newSlippage);

    // Pool parameters
    address public lpVault;
    address public curve;
    uint256 public slippage;

    function __StrategyCurveBase__init(address _vault, address _lpVault, address _curve) internal initializer {
        __StrategyBase_init(_vault);

        require(_lpVault != address(0x0), "LP vault not set");
        require(_curve != address(0x0), "curve not set");
        lpVault = _lpVault;
        curve = _curve;

        slippage = 100; // 1% max slippage
    }

    /**
     * @dev Invests the free token balance in the strategy.
     */
    function deposit() public virtual override authorized {
        IERC20Upgradeable want = IERC20Upgradeable(token());
        uint256 _want = want.balanceOf(address(this));
        if (_want > 0) {
            want.safeApprove(curve, 0);
            want.safeApprove(curve, _want);
            uint256 v = _want.mul(1e18).mul(_getLpRate()).div(ICurveFi(curve).get_virtual_price());
            _depositToCurve(_want, v.mul(PERCENT_MAX.sub(slippage)).div(PERCENT_MAX));
        }

        IERC20Upgradeable lp = IERC20Upgradeable(IVault(lpVault).token());
        uint256 _lp = lp.balanceOf(address(this));
        if (_lp > 0) {
            lp.safeApprove(lpVault, 0);
            lp.safeApprove(lpVault, _lp);
            IVault(lpVault).deposit(_lp);
        }
    }

    /**
     * @dev Withdraw partial funds, normally used with a vault withdrawal
     */
    function withdraw(uint256 _amount) public override {
        require(msg.sender == vault, "not vault");
        IERC20Upgradeable want = IERC20Upgradeable(token());
        uint256 _balance = want.balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        if (withdrawalFee > 0) {
            uint256 _feeAmount = _amount.mul(withdrawalFee).div(PERCENT_MAX);
            want.safeTransfer(IController(controller()).treasury(), _feeAmount);
            _amount = _amount.sub(_feeAmount);
        }

        want.safeTransfer(vault, _amount);
    }

    /**
     * @dev Returns the conversion rate between the want token and the LP token.
     */
    function _getLpRate() internal view returns (uint256) {
        return uint256(10) ** (18 - ERC20Upgradeable(token()).decimals());
    }

    /**
     * @dev Withdraw specific amount of want token from the strategy.
     * @param _amount Amount of want token to withdraw.
     */
    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        IERC20Upgradeable lp = IERC20Upgradeable(IVault(lpVault).token());

        // The amount of LP token needed to withdraw from Curve
        uint256 _lp = _amount.mul(1e18).mul(_getLpRate()).div(ICurveFi(curve).get_virtual_price());
        // The amount of LP vault share needed to withdraw from LP vault
        uint256 _lpVault = _lp.mul(1e18).div(IVault(lpVault).getPricePerFullShare());
        // Withdraws from LP vault
        uint256 _lpBefore = lp.balanceOf(address(this));
        IVault(lpVault).withdraw(_lpVault);
        uint256 _lpAfter = lp.balanceOf(address(this));

        // Converts the withdrawn LP to want token.
        return _withdrawOne(_lpAfter.sub(_lpBefore));
    }

    /**
     * @dev Withdraws one token from the Curve swap.
     * @param _lp Amount of LP token to withdraw.
     */
    function _withdrawOne(uint256 _lp) internal virtual returns (uint256) {
        IERC20Upgradeable want = IERC20Upgradeable(token());
        uint256 _before = want.balanceOf(address(this));

        IERC20Upgradeable lp = IERC20Upgradeable(IVault(lpVault).token());
        lp.safeApprove(curve, 0);
        lp.safeApprove(curve, _lp);
        _withdrawFromCurve(_lp, _lp.mul(PERCENT_MAX.sub(slippage)).div(PERCENT_MAX).div(_getLpRate()));
        uint256 _after = want.balanceOf(address(this));

        return _after.sub(_before);
    }

    /**
     * @dev Withdraw all funds, normally used when migrating strategies
     * No withdrawal fee is charged when withdrawing all assets.
     */
    function withdrawAll() public override returns (uint256 balance) {
        require(msg.sender == vault, "not vault");

        // Exists from the lp vault, withdraws all lp tokens and claims all rewards.
        IVault(lpVault).exit();

        // Withdraws want token from the withdrawn lp tokens.
        uint256 _lp = IERC20Upgradeable(IVault(lpVault).token()).balanceOf(address(this));
        if (_lp > 0) {
            _withdrawOne(_lp);
        }
        IERC20Upgradeable want = IERC20Upgradeable(token());
        balance = want.balanceOf(address(this));
        want.safeTransfer(vault, balance);

        // Distributes the reward token to the vault.
        IERC20Upgradeable rewardToken = IERC20Upgradeable(IController(controller()).rewardToken());
        uint256 _reward = rewardToken.balanceOf(address(this));
        if (_reward > 0) {
            rewardToken.safeApprove(vault, 0);
            rewardToken.safeApprove(vault, _reward);
            IVault(vault).addRewards(_reward);
        }
    }

    /**
     * @dev Returns the amount of want token hold by the strategy.
     */
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(token()).balanceOf(address(this));
    }

    /**
     * @dev Returns the amount of LP token hold by the strategy.
     */
    function balanceOfLp() public view returns (uint256) {
        return IERC20Upgradeable(IVault(lpVault).token()).balanceOf(address(this));
    }

    /**
     * @dev Returns the value of LP token hold by the strategy in the unit of want token.
     */
    function balanceOfLpInWant() public view returns (uint256) {
        return balanceOfLp().mul(ICurveFi(curve).get_virtual_price()).div(1e18).div(_getLpRate());
    }

    /**
     * @dev Returns the amount of LP vault shares hold the strategy.
     */
    function balanceOfLpVault() public view returns (uint256) {
        return IERC20Upgradeable(lpVault).balanceOf(address(this));
    }

    /**
     * @dev Returns the value of LP vault shares hold the strategy in the unit of LP token.
     */
    function balanceOfLpVaultInLp() public view returns (uint256) {
        return balanceOfLpVault().mul(IVault(lpVault).getPricePerFullShare()).div(1e18);
    }

    /**
     * @dev Returns the values of LP vault shares hold by the strategy in the unit of want token.
     */
    function balanceOfLpVaultInWant() public view returns (uint256) {
        return balanceOfLpVaultInLp().mul(ICurveFi(curve).get_virtual_price()).div(1e18).div(_getLpRate());
    }

    /**
     * @dev Returns the total balance of the strategy in the unit of want token.
     */
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant().add(balanceOfLpVaultInWant());
    }

    /**
     * @dev Updates the slippage threshold for Curve swap.
     */
    function setSlippage(uint256 _slippage) public onlyStrategist {
        require(_slippage <= PERCENT_MAX, "overflow");
        uint256 oldSlippage = slippage;
        slippage = _slippage;

        emit SlippageUpdated(oldSlippage, _slippage);
    }

    /**
     * @dev Harvest reward from LP vault and distributes to the vault users.
     */
    function harvest() public override authorized {
        // The actual yield harvest is done together in the lp vault,
        // so yield harvest on want token is performed here.
        // Instead, we harvest the reward token from the LP vault and distributes
        // it in the vaule.
        IVault(lpVault).claimReward();
        IERC20Upgradeable rewardToken = IERC20Upgradeable(IController(controller()).rewardToken());
        uint256 _reward = rewardToken.balanceOf(address(this));
        if (_reward > 0) {
            rewardToken.safeApprove(vault, 0);
            rewardToken.safeApprove(vault, _reward);
            IVault(vault).addRewards(_reward);
        }
    }

    /**
     * @dev Return the list of tokens that should not be salvaged.
     */
    function _getProtectedTokens() internal virtual override view returns (address[] memory) {
        address[] memory protectedTokens = new address[](3);
        protectedTokens[0] = token();
        protectedTokens[1] = IVault(lpVault).token();
        protectedTokens[2] = lpVault;
        return protectedTokens;
    }

    /**
     * @dev Deposits the want token into Curve in exchange for lp token.
     * @param _want Amount of want token to deposit.
     * @param _minAmount Minimum LP token to receive.
     */
    function _depositToCurve(uint256 _want, uint256 _minAmount) internal virtual {}

    /**
     * @dev Withdraws the want token from Curve by burning lp token.
     * @param _lp Amount of LP token to burn.
     * @param _minAmount Minimum want token to receive.
     */
    function _withdrawFromCurve(uint256 _lp, uint256 _minAmount) internal virtual {}
}