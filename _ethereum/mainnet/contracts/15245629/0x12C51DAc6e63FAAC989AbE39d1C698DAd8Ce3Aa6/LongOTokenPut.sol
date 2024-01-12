// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import "./RollOverBase.sol";
import "./GammaUtils.sol";
// use airswap to long
import "./AirswapUtils.sol";

import "./SwapTypes.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IController.sol";
import "./IActionLongOToken.sol";
import "./IOracle.sol";
import "./IOToken.sol";
import "./IStakeDao.sol";
import "./ICurveZap.sol";
import "./SwapHelper.sol";

/**
 * This is an Long Action template that inherit lots of util functions to "Long" an option.
 * You can remove the function you don't need.
 */
contract LongOTokenPut is
    IActionLongOToken,
    AirswapUtils,
    RollOverBase,
    GammaUtils
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @dev 100%
    uint256 public constant BASE = 10000;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public rolloverTime;

    address public immutable vault;
    address public immutable asset;
    IStakeDao public stakedaoStrategy;
    address public curveZap;
    IERC20 public curveLPToken;
    IOracle public oracle;
    SwapHelper public swapHelper;

    constructor(
        address _vault,
        address _asset,
        address _airswap,
        address _controller,
        IStakeDao _stakedaoStrategy,
        address _curveZap,
        SwapHelper _swapHelper
    ) {
        vault = _vault;
        asset = _asset;
        stakedaoStrategy = _stakedaoStrategy;
        curveLPToken = stakedaoStrategy.token();
        curveZap = _curveZap;
        swapHelper = _swapHelper;

        // enable vault to take all the asset back and re-distribute.
        IERC20(_asset).safeApprove(_vault, uint256(-1));
        IERC20(USDC).safeApprove(address(swapHelper), uint256(-1));
        curveLPToken.safeApprove(address(curveZap), uint256(-1));
        _initGammaUtil(_controller);

        oracle = IOracle(controller.oracle());

        _initSwapContract(_airswap);

        _initRollOverBase(controller.whitelist());
    }

    modifier onlyVault() {
        require(msg.sender == vault, "!VAULT");

        _;
    }

    /**
     * @dev return the net worth of this strategy, in terms of asset.
     * if the action has an opened gamma vault, see if there's any short position
     */
    function currentValue() external view override returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
        // todo: add cash value of the otoken that we're long
    }

    /**
     * @dev the function that the vault will call when the round is over
     */
    function closePosition(uint256 minUsdcAmount, uint256 minWethAmount)
        external
        override
        onlyVault
    {
        require(canClosePosition(), "Cannot close position");
        if (otoken != address(0)) {
            uint256 amount = IERC20(otoken).balanceOf(address(this));
            _redeemOTokens(otoken, amount);

            // todo: convert asset get from redeem to the asset this strategy is based on
            IStakeDao(stakedaoStrategy).withdrawAll();
            uint256 curveLPTokenToWithdraw = curveLPToken.balanceOf(
                address(this)
            );
            if (curveLPTokenToWithdraw > 0) {
                ICurveZap(curveZap).remove_liquidity_one_coin(
                    address(curveLPToken),
                    curveLPTokenToWithdraw,
                    2,
                    minUsdcAmount
                );
                uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
                swapHelper.swap(usdcBalance, minWethAmount);
            }
        }
        _setActionIdle();
    }

    /**
     * @dev the function that the vault will call when the new round is starting
     */
    function rolloverPosition() external override onlyVault {
        _rollOverNextOTokenAndActivate(); // this function can only be called when the action is `Committed`
        rolloverTime = block.timestamp;
    }

    /**
     * @notice the function will return when someone can close a position. 1 day after rollover,
     * if the option wasn't sold, anyone can close the position.
     */
    function canClosePosition() public view returns (bool) {
        if (otoken != address(0)) {
            return controller.isSettlementAllowed(otoken);
        }
        // no otoken committed or longing
        return block.timestamp > rolloverTime + 1 days;
    }

    // Long Functions
    // Keep the functions you need to buy otokens.

    /**
     * @dev execute OTC trade to buy oToken.
     */
    function tradeAirswapOTC(SwapTypes.Order memory _order) external onlyOwner {
        onlyActivated();
        require(_order.sender.wallet == address(this), "!Sender");
        require(_order.sender.token == asset, "Can only pay with asset");
        require(_order.signer.token == otoken, "Can only buy otoken");

        _fillAirswapOrder(_order);
    }

    function changeSwapHelper(SwapHelper _newSwapHelper) external onlyOwner {
        swapHelper = _newSwapHelper;
        IERC20(USDC).approve(address(_newSwapHelper), uint256(-1));
    }

    // End of Long Funtions

    // Custom Checks

    /**
     * @dev funtion to add some custom logic to check the next otoken is valid to this strategy
     * this hook is triggered while action owner calls "commitNextOption"
     * so accessing otoken will give u the current otoken.
     */
    function _customOTokenCheck(address _nextOToken) internal view {
        IOToken otokenToCheck = IOToken(_nextOToken);
        require(
            _isValidStrike(
                otokenToCheck.underlyingAsset(),
                otokenToCheck.strikePrice(),
                otokenToCheck.isPut()
            ),
            "Bad Strike Price"
        );
        require(
            _isValidExpiry(otokenToCheck.expiryTimestamp()),
            "Invalid expiry"
        );
        // add more checks here
    }

    /**
     * @dev funtion to check that the otoken being sold meets a minimum valid strike price
     * this hook is triggered in the _customOtokenCheck function.
     */
    function _isValidStrike(
        address _underlying,
        uint256 strikePrice,
        bool isPut
    ) internal view returns (bool) {
        // TODO: override with your filler code.
        // Example: checks that the strike price set is > than 105% of current price for calls, < 95% spot price for puts
        uint256 spotPrice = oracle.getPrice(_underlying);
        if (isPut) {
            return strikePrice <= spotPrice.mul(9500).div(BASE);
        } else {
            return strikePrice >= spotPrice.mul(10500).div(BASE);
        }
    }

    /**
     * @dev funtion to check that the otoken being sold meets certain expiry conditions
     * this hook is triggered in the _customOtokenCheck function.
     */
    function _isValidExpiry(uint256 expiry) internal view returns (bool) {
        // TODO: override with your filler code.
        // Checks that the token committed to expires within 15 days of commitment.
        return (block.timestamp).add(15 days) >= expiry;
    }
}
