// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import "./FixedPointMathLib.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./TradingDays.sol";

// interfaces
import "./IAllowlist.sol";
import "./IMasterFundAdmin.sol";
import "./IERC20Metadata.sol";
import "./IYieldTokenOracle.sol";
import "./IYieldToken.sol";

// errors and constants
import "./constants.sol";
import "./errors.sol";

/**
 * @title   Yield Token Teller
 * @author  dsshap
 * @dev     Provides liquidity for yield token/stablecoin pair.
 */
contract YieldTokenTeller is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, TradingDays {
    using FixedPointMathLib for uint256;
    using LibDateTime for uint256;
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IYieldToken;

    /*///////////////////////////////////////////////////////////////
                        Constants & Immutables
    //////////////////////////////////////////////////////////////*/

    IYieldToken public immutable ytoken;

    uint8 private immutable ytokenDecimals;

    IERC20Metadata public immutable stable;

    uint8 private immutable stableDecimals;

    IYieldTokenOracle public immutable oracle;

    uint8 private immutable oracleDecimals;

    /// @notice allowlist manager to check permissions
    IAllowlist public immutable allowlist;

    /// @notice fund admin to subscribe and redeem
    IMasterFundAdmin public immutable masterFundAdmin;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Bought(address indexed from, uint256 amount, uint256 paid, uint256 price);

    event Sold(address indexed from, uint256 amount, uint256 received, uint256 fee);

    event LiquidityProviderSet(address previousLp, address newLp);

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @notice the address of the liquidity provider
    address public liquidityProvider;

    /*///////////////////////////////////////////////////////////////
                         State Variables V2
    //////////////////////////////////////////////////////////////*/

    /// @notice the trading start hour
    uint256 public tradingStartHour;

    /// @notice the trading end hour
    uint256 public tradingEndHour;

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _ytoken,
        address _stable,
        address _oracle,
        address _holidays,
        address _dst,
        address _allowlist,
        address _masterFundAdmin
    ) TradingDays(_holidays, _dst) initializer {
        if (_ytoken == address(0)) revert BadAddress();
        if (_stable == address(0)) revert BadAddress();
        if (_oracle == address(0)) revert BadAddress();
        if (_allowlist == address(0)) revert BadAddress();
        if (_masterFundAdmin == address(0)) revert BadAddress();

        ytoken = IYieldToken(_ytoken);
        ytokenDecimals = ytoken.decimals();

        stable = IERC20Metadata(_stable);
        stableDecimals = stable.decimals();

        oracle = IYieldTokenOracle(_oracle);
        oracleDecimals = oracle.decimals();

        allowlist = IAllowlist(_allowlist);
        masterFundAdmin = IMasterFundAdmin(_masterFundAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner, address _liquidityProvider, uint256 _startHour, uint256 _endHour) external initializer {
        if (_owner == address(0)) revert BadAddress();
        if (_liquidityProvider == address(0)) revert BadAddress();
        if (_startHour >= _endHour) revert InvalidTradingWindow();

        _transferOwnership(_owner);

        liquidityProvider = _liquidityProvider;
        tradingStartHour = _startHour;
        tradingEndHour = _endHour;
    }

    /*///////////////////////////////////////////////////////////////
                        Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */

    function _authorizeUpgrade(address /*newImplementation*/ ) internal virtual override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                            LP Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update the liquidity provider
     * @param _liquidityProvider is the address of the new liquidity provider
     */
    function setLiquidityProvider(address _liquidityProvider) external {
        _checkOwner();

        if (_liquidityProvider == address(0)) revert BadAddress();

        emit LiquidityProviderSet(liquidityProvider, _liquidityProvider);

        liquidityProvider = _liquidityProvider;
    }

    /**
     * @notice Liquidity provider can fund stablecoin
     * @param _amount is the amount of stable to transfer
     */
    function fund(uint256 _amount) external {
        if (msg.sender != liquidityProvider) revert NoAccess();

        if (_amount > 0) stable.safeTransferFrom(msg.sender, address(this), _amount);
        else revert BadAmount();
    }

    /**
     * @notice Liquidity provider can redeem Yield Token and stablecoin
     * @param _ytokenAmount is the amount of ytoken to transfer
     * @param _stableAmount is the amount of stable to transfer
     */
    function redeem(uint256 _ytokenAmount, uint256 _stableAmount) external {
        if (msg.sender != liquidityProvider) revert NoAccess();

        if (_ytokenAmount > 0) ytoken.safeTransfer(msg.sender, _ytokenAmount);
        if (_stableAmount > 0) stable.safeTransfer(msg.sender, _stableAmount);
    }

    function setTradingHours(uint256 _startHour, uint256 _endHour) external {
        _checkOwner();
        if (_startHour >= _endHour) revert InvalidTradingWindow();

        tradingStartHour = _startHour;
        tradingEndHour = _endHour;
    }

    /*///////////////////////////////////////////////////////////////
                            Client Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Purchase Yield Token and pays in stablecoin
     * @param _amount is the amount of stable coin to pay
     * @return amount of Yield Token to purchase
     */
    function buy(uint256 _amount) external nonReentrant returns (uint256) {
        return _buyFor(_amount, msg.sender);
    }

    /**
     * @notice Purchase Yield Token and pays in stablecoin
     * @dev Yield Token transferred to the recipient
     * @param _amount is the amount of stablecoin to pay
     * @param _recipient is the address of the recipient
     * @return amount amount of Yield Token to purchase
     */
    function buyFor(uint256 _amount, address _recipient) external nonReentrant returns (uint256) {
        return _buyFor(_amount, _recipient);
    }

    /**
     * @notice Sells Yield Token and receives stablecoin
     * @param _amount is the amount of Yield Token to sell
     * @return amount amount of stablecoin received
     */
    function sell(uint256 _amount) external nonReentrant returns (uint256) {
        return _sellForWithVerification(_amount, msg.sender);
    }

    /**
     * @notice Sells Yield Token and receives stablecoin
     * @dev Stablecoin transferred to the recipient
     * @param _amount is the amount of Yield Token to sell
     * @param _recipient is the address of the recipient
     * @return amount amount of stablecoin received
     */
    function sellFor(uint256 _amount, address _recipient) external nonReentrant returns (uint256) {
        return _sellForWithVerification(_amount, _recipient);
    }

    /**
     * @notice Preview a sale of Yield Token
     * @dev produces the anticipated payout and fees using a price
     * @param _amount is the amount of Yield Token to sell
     * @return payout amount of stablecoin received
     * @return fee taken
     * @return price used in conversion
     */
    function sellPreview(uint256 _amount) external view returns (uint256, uint256, int256) {
        return _sellPreview(_amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Purchase Yield Token and pays in stablecoin
     * @param _amount is the amount of stablecoin to deposit
     * @param _recipient is the address of the recipient
     * @return amount amount of Yield Token to purchase
     */
    function _buyFor(uint256 _amount, address _recipient) internal virtual returns (uint256 amount) {
        State s = state();

        if (s == State.HOLIDAY) revert ClosedForHoliday(getHoliday());
        else if (s == State.WEEKEND) revert ClosedForWeekend();
        else if (s == State.AFTER_HOURS) revert AfterHours();

        stable.safeTransferFrom(msg.sender, address(this), _amount);

        // if client is subscribed to feeders, then funds must enter through them
        if (allowlist.isClientFeeder(_recipient)) {
            stable.approve(address(masterFundAdmin), _amount);
            masterFundAdmin.subscribe(address(this), address(stable), _amount, _recipient, address(this));
        }

        // rounding to USD decimals {2}
        if (stableDecimals > 2) amount = _amount / 10 ** (stableDecimals - 2);
        else if (stableDecimals < 2) amount = _amount * (10 ** (2 - stableDecimals));
        // scaling to Yield Token decimals {6}
        amount *= 10 ** (ytokenDecimals - 2);

        (, int256 answer,,,) = oracle.latestRoundData();
        amount = amount.mulDivDown(10 ** oracleDecimals, uint256(answer));

        uint256 ytokenBalance = ytoken.balanceOf(address(this));

        // transfer ytoken from teller first then mint the remainder
        if (ytokenBalance < amount) {
            uint256 payout;

            if (ytokenBalance > 0) {
                payout = ytokenBalance.mulDivDown(uint256(answer), 10 ** oracleDecimals);

                // scaling to cents
                payout = payout / (10 ** (ytokenDecimals - 2));

                // scaling to stable decimals
                if (stableDecimals > 2) payout *= 10 ** (stableDecimals - 2);
                else if (stableDecimals < 2) payout /= 10 ** (2 - stableDecimals);

                ytoken.safeTransfer(_recipient, ytokenBalance);
            }

            // transfer and mint remainder
            stable.safeTransfer(address(ytoken), _amount - payout);
            ytoken.mint(_recipient, amount - ytokenBalance);
        } else {
            ytoken.safeTransfer(_recipient, amount);
        }

        emit Bought(msg.sender, amount, _amount, uint256(answer));
    }

    /**
     * @notice Sells Yield Token and receives stablecoin
     * @param _amount is the amount of Yield Token to burn
     * @param _recipient is the address of the recipient
     * @return payout amount of stablecoin received
     */
    function _sellForWithVerification(uint256 _amount, address _recipient) internal virtual returns (uint256 payout) {
        uint256 ytokenBalBefore = ytoken.balanceOf(address(this));
        uint256 stableBalBefore = stable.balanceOf(address(this));

        int256 price;
        (payout, price) = _sellFor(_amount, _recipient);

        uint256 ytokenBalAfter = ytoken.balanceOf(address(this));
        uint256 stableBalAfter = stable.balanceOf(address(this));

        uint256 scale = 10 ** oracleDecimals;

        // calculating NAV, rounding up
        uint256 navBefore = ytokenBalBefore.mulDivUp(uint256(price), scale);
        uint256 navAfter = ytokenBalAfter.mulDivUp(uint256(price), scale);

        if (stableDecimals > ytokenDecimals) {
            scale = 10 ** (stableDecimals - ytokenDecimals);

            stableBalBefore /= scale;
            stableBalAfter /= scale;
        } else {
            scale = 10 ** (ytokenDecimals - stableDecimals);

            stableBalBefore *= scale;
            stableBalAfter *= scale;
        }

        // The teller NAV should never go down after a sale
        if (navBefore + stableBalBefore > navAfter + stableBalAfter) revert BadAmount();
    }

    /**
     * @notice Sells Yield Token and receives stablecoin
     * @param _amount is the amount of Yield Token to burn
     * @param _recipient is the address of the recipient
     * @return payout amount of stablecoin received
     */
    function _sellFor(uint256 _amount, address _recipient) internal virtual returns (uint256 payout, int256 price) {
        if (!allowlist.isAllowed(_recipient)) revert NotPermissioned();
        if (_amount == 0) revert BadAmount();

        uint256 fee;
        (payout, fee, price) = _sellPreview(_amount);

        ytoken.safeTransferFrom(msg.sender, address(this), _amount);

        // if client is subscribed to feeders, then funds must exit through them
        if (allowlist.isClientFeeder(_recipient)) {
            stable.approve(address(masterFundAdmin), payout);
            masterFundAdmin.redeem(address(this), address(stable), payout, _recipient, _recipient);
        } else {
            stable.safeTransfer(_recipient, payout);
        }

        emit Sold(_recipient, _amount, payout, fee);
    }

    function _sellPreview(uint256 _amount) internal view virtual returns (uint256 payout, uint256 fee, int256 price) {
        // current price in terms of USD
        uint80 roundId;
        (roundId, price,,,) = oracle.latestRoundData();
        payout = _amount.mulDivDown(uint256(price), 10 ** oracleDecimals);

        // using the last reported interest amount to calculate the fee
        (,, uint256 interest, uint256 totalSupply,) = oracle.getRoundDetails(roundId);
        fee = _amount.mulDivDown(interest, totalSupply);

        // scaling to cents
        payout = payout / (10 ** (ytokenDecimals - 2));

        // scaling to stable decimals
        if (stableDecimals > 2) {
            uint256 scale = 10 ** (stableDecimals - 2);

            payout = payout * scale;
            fee = fee * scale;
        } else if (stableDecimals < 2) {
            uint256 scale = 10 ** (2 - stableDecimals);

            payout = payout / scale;
            fee = fee / scale;
        }

        // subtracting fee from the payout
        payout -= fee;
    }

    /// @notice override start hour for TradingDays
    function _tradingStartHour() internal view override returns (uint256) {
        return tradingStartHour;
    }

    /// @notice override end hour for TradingDays
    function _tradingEndHour() internal view override returns (uint256) {
        return tradingEndHour;
    }
}
