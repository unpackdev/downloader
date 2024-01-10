// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "SafeERC20.sol";
import "Initializable.sol";
import "ERC20.sol";
import "UUPSUpgradeable.sol";
import {BoringOwnable} from "BoringOwnable.sol";
import {EIP1271Wallet} from "EIP1271Wallet.sol";
import {IVault, IAsset} from "IVault.sol";
import {NotionalTreasuryAction} from "NotionalTreasuryAction.sol";
import {WETH9} from "WETH9.sol";
import "IPriceOracle.sol";
import "IExchangeV3.sol";

contract TreasuryManager is
    EIP1271Wallet,
    BoringOwnable,
    Initializable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    /// @notice precision used to limit the amount of NOTE price impact (1e8 = 100%)
    uint256 internal constant NOTE_PURCHASE_LIMIT_PRECISION = 1e8;

    NotionalTreasuryAction public immutable NOTIONAL;
    IERC20 public immutable NOTE;
    address public immutable ASSET_PROXY;
    IExchangeV3 public immutable EXCHANGE;
    uint32 public constant MAXIMUM_COOL_DOWN_PERIOD_SECONDS = 30 days;

    address public manager;

    /// @notice This limit determines the maximum price impact (% increase from current oracle price)
    /// from joining the BPT pool with WETH
    uint256 public notePurchaseLimit;

    /// @notice Number of seconds that need to pass before another investWETHAndNOTE can be called
    uint32 public coolDownTimeInSeconds;
    uint32 public lastInvestTimestamp;

    event ManagementTransferred(address prevManager, address newManager);
    event AssetsHarvested(uint16[] currencies, uint256[] amounts);
    event COMPHarvested(address[] ctokens, uint256 amount);
    event NOTEPurchaseLimitUpdated(uint256 purchaseLimit);
    event OrderCancelled(
        uint8 orderStatus,
        bytes32 orderHash,
        uint256 orderTakerAssetFilledAmount
    );

    /// @notice Emitted when cool down time is updated
    event InvestmentCoolDownUpdated(uint256 newCoolDownTimeSeconds);
    event AssetsInvested(uint256 wethAmount, uint256 noteAmount);

    /// @dev Restricted methods for the treasury manager
    modifier onlyManager() {
        require(msg.sender == manager, "Unauthorized");
        _;
    }

    constructor(
        NotionalTreasuryAction _notional,
        WETH9 _weth,
        IERC20 _note,
        address _assetProxy,
        IExchangeV3 _exchange
    ) EIP1271Wallet(_weth) initializer {
        // Balancer will revert if pool is not found
        // prettier-ignore
        NOTIONAL = NotionalTreasuryAction(_notional);
        NOTE = _note;
        ASSET_PROXY = _assetProxy;
        EXCHANGE = _exchange;
    }

    function initialize(
        address _owner,
        address _manager,
        uint32 _coolDownTimeInSeconds
    ) external initializer {
        owner = _owner;
        manager = _manager;
        coolDownTimeInSeconds = _coolDownTimeInSeconds;
        emit OwnershipTransferred(address(0), _owner);
        emit ManagementTransferred(address(0), _manager);
    }

    function approveToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeApprove(ASSET_PROXY, 0);
        IERC20(token).safeApprove(ASSET_PROXY, amount);
    }

    function setPriceOracle(address tokenAddress, address oracleAddress)
        external
        onlyOwner
    {
        /// @dev oracleAddress validated inside _setPriceOracle
        _setPriceOracle(tokenAddress, oracleAddress);
    }

    function setSlippageLimit(address tokenAddress, uint256 slippageLimit)
        external
        onlyOwner
    {
        /// @dev slippageLimit validated inside _setSlippageLimit
        _setSlippageLimit(tokenAddress, slippageLimit);
    }

    function setNOTEPurchaseLimit(uint256 purchaseLimit) external onlyOwner {
        require(
            purchaseLimit <= NOTE_PURCHASE_LIMIT_PRECISION,
            "purchase limit is too high"
        );
        notePurchaseLimit = purchaseLimit;
        emit NOTEPurchaseLimitUpdated(purchaseLimit);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        if (amount == type(uint256).max)
            amount = IERC20(token).balanceOf(address(this));
        if (amount > 0) IERC20(token).safeTransfer(msg.sender, amount);
    }

    function wrapToWETH() external onlyManager {
        WETH.deposit{value: address(this).balance}();
    }

    function setManager(address newManager) external onlyOwner {
        emit ManagementTransferred(manager, newManager);
        manager = newManager;
    }

    /// @notice cancelOrder needs to be proxied because 0x expects makerAddress to be address(this)
    /// @param order 0x order object
    function cancelOrder(IExchangeV3.Order calldata order)
        external
        onlyManager
    {
        IExchangeV3.OrderInfo memory info = EXCHANGE.getOrderInfo(order);
        EXCHANGE.cancelOrder(order);
        emit OrderCancelled(
            info.orderStatus,
            info.orderHash,
            info.orderTakerAssetFilledAmount
        );
    }

    /*** Manager Functionality  ***/

    /// @dev Will need to add a this method as a separate action behind the notional proxy
    function harvestAssetsFromNotional(uint16[] calldata currencies)
        external
        onlyManager
    {
        uint256[] memory amountsTransferred = NOTIONAL
            .transferReserveToTreasury(currencies);
        emit AssetsHarvested(currencies, amountsTransferred);
    }

    function harvestCOMPFromNotional(address[] calldata ctokens)
        external
        onlyManager
    {
        uint256 amountTransferred = NOTIONAL.claimCOMPAndTransfer(ctokens);
        emit COMPHarvested(ctokens, amountTransferred);
    }

    /// @notice Updates the required cooldown time to invest
    function setCoolDownTime(uint32 _coolDownTimeInSeconds) external onlyOwner {
        require(_coolDownTimeInSeconds <= MAXIMUM_COOL_DOWN_PERIOD_SECONDS);
        coolDownTimeInSeconds = _coolDownTimeInSeconds;
        emit InvestmentCoolDownUpdated(_coolDownTimeInSeconds);
    }

    function isValidSignature(bytes calldata data, bytes calldata signature)
        external
        view
        returns (bytes4)
    {
        return _isValidSignature(data, signature, manager);
    }

    function _safe32(uint256 x) internal pure returns (uint32) {
        require (x <= type(uint32).max);
        return uint32(x);
    }

    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal override onlyOwner {}
}
