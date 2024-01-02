//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./Registry.sol";
import "./Entity.sol";
import "./EndaomentAuth.sol";
import "./Math.sol";

abstract contract Portfolio is ERC20, EndaomentAuth, ReentrancyGuard {
    using Math for uint256;
    using SafeTransferLib for ERC20;

    Registry public immutable registry;
    uint256 public cap;
    address public feeTreasury;
    uint256 public depositFee;
    uint256 public redemptionFee;
    address public immutable asset;
    address public immutable receiptAsset;
    ERC20 public immutable baseToken;
    bool public didShutdown;
    uint256 public timestampAumFeesTaken;
    uint256 public aumRate;
    uint256 internal constant MAX_AUM_RATE = 3168808782;

    error InvalidSwapper();
    error InvalidRate();
    error TransferDisallowed();
    error DepositAfterShutdown();
    error DidShutdown();
    error NotEntity();
    error BadCheckCapImplementation();
    error ExceedsCap();
    error PercentageOver100();
    error RoundsToZero();
    error Slippage();
    error CallFailed(bytes response);

    /// @notice `sender` has exchanged `assets` (after fees) for `shares`, and transferred those `shares` to `receiver`.
    /// The sender paid a total of `depositAmount` and was charged `fee` for the transaction.
    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares,
        uint256 depositAmount,
        uint256 fee
    );

    /// @notice `sender` has exchanged `shares` for `assets`, and transferred those `assets` to `receiver`.
    /// The sender received a net of `redeemedAmount` after the conversion of `assets` into base tokens
    /// and was charged `fee` for the transaction.
    event Redeem(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares,
        uint256 redeemedAmount,
        uint256 fee
    );

    /// @notice Event emitted when `cap` is set.
    event CapSet(uint256 cap);

    /// @notice Event emitted when `depositFee` is set.
    event DepositFeeSet(uint256 fee);

    /// @notice Event emitted when `redemptionFee` is set.
    event RedemptionFeeSet(uint256 fee);

    /// @notice Event emitted when `feeTreasury` is set.
    event FeeTreasurySet(address feeTreasury);

    /// @notice Event emitted when management takes fees.
    event FeesTaken(uint256 amount);

    /// @notice Event emitted when AUM fees are taken.
    event AumFeesTaken(uint256 feeAmount, uint256 timeDelta);

    /// @notice Event emitted when `aumRate` is set.
    event AumRateSet(uint256 rate);

    /// @notice Event emitted when admin forcefully swaps portfolio asset balance for baseToken.
    event Shutdown(uint256 assetAmount, uint256 baseTokenOut);

    /**
     * @param _registry Endaoment registry.
     * @param _receiptAsset Address of token that the portfolio receives from a deposit.
     * @param _name Name of the ERC20 Portfolio share tokens.
     * @param _symbol Symbol of the ERC20 Portfolio share tokens.
     * @param _cap Amount in baseToken that value of totalAssets should not exceed.
     * @param _depositFee Percentage fee as ZOC that will go to treasury on asset deposit.
     * @param _redemptionFee Percentage fee as ZOC that will go to treasury on share redemption.
     * @param _aumRate Percentage fee per second (as WAD) that should accrue to treasury as AUM fee. (1e16 = 1%).
     */
    constructor(
        Registry _registry,
        address _receiptAsset,
        string memory _name,
        string memory _symbol,
        uint256 _cap,
        address _feeTreasury,
        uint256 _depositFee,
        uint256 _redemptionFee,
        uint256 _aumRate
    ) ERC20(_name, _symbol, ERC20(_getAsset(_receiptAsset)).decimals()) {
        __initEndaomentAuth(_registry, "portfolio");
        registry = _registry;

        feeTreasury = _feeTreasury;
        emit FeeTreasurySet(_feeTreasury);

        if (_redemptionFee > Math.ZOC) revert PercentageOver100();
        redemptionFee = _redemptionFee;
        emit RedemptionFeeSet(_redemptionFee);

        if (_depositFee > Math.ZOC) revert PercentageOver100();
        depositFee = _depositFee;
        emit DepositFeeSet(_depositFee);

        cap = _cap;
        emit CapSet(_cap);

        receiptAsset = _receiptAsset;
        asset = _getAsset(_receiptAsset);
        baseToken = registry.baseToken();

        if (_aumRate > MAX_AUM_RATE) revert InvalidRate();
        aumRate = _aumRate;
        emit AumRateSet(_aumRate);

        timestampAumFeesTaken = block.timestamp;
    }

    /**
     * @notice Returns the underlying asset for the `receiptAsset`.
     * @param _receiptAsset Address of token that the portfolio receives from a deposit.
     * @return Address of the underlying asset.
     */
    function _getAsset(address _receiptAsset) internal view virtual returns (address);

    /**
     * @notice Function used to determine whether an Entity is active on the registry.
     * @param _entity The Entity.
     */
    function _isEntity(Entity _entity) internal view returns (bool) {
        return registry.isActiveEntity(_entity);
    }

    /**
     * @notice Set the Portfolio cap.
     * @param _amount Amount, denominated in baseToken.
     */
    function setCap(uint256 _amount) external requiresAuth {
        cap = _amount;
        emit CapSet(_amount);
    }

    /**
     * @notice Set deposit fee.
     * @param _pct Percentage as ZOC (e.g. 1000 = 10%).
     */
    function setDepositFee(uint256 _pct) external requiresAuth {
        if (_pct > Math.ZOC) revert PercentageOver100();
        depositFee = _pct;
        emit DepositFeeSet(_pct);
    }

    /**
     * @notice Set redemption fee.
     * @param _pct Percentage as ZOC (e.g. 1000 = 10%).
     */
    function setRedemptionFee(uint256 _pct) external requiresAuth {
        if (_pct > Math.ZOC) revert PercentageOver100();
        redemptionFee = _pct;
        emit RedemptionFeeSet(_pct);
    }

    /**
     * @notice Set fee treasury.
     * @param _feeTreasury Address of the treasury that should receive fees.
     *
     */
    function setFeeTreasury(address _feeTreasury) external requiresAuth {
        feeTreasury = _feeTreasury;
        emit FeeTreasurySet(_feeTreasury);
    }

    /**
     * @notice Set AUM rate.
     * @param _pct Percentage *per second* as WAD (e.g. .01e18 / 365.25 days = 1% per year).
     */
    function setAumRate(uint256 _pct) external requiresAuth {
        // check to make sure _pct isn't above 10% over a year (.1e18 / 365.25 days = 3168808782 per second)
        if (_pct > MAX_AUM_RATE) revert InvalidRate();
        takeAumFees();
        aumRate = _pct;
        emit AumRateSet(_pct);
    }

    /**
     * @notice Total amount of the underlying asset that is managed by the Portfolio.
     * @return Total amount of the underlying asset.
     */
    function totalAssets() public view returns (uint256) {
        return convertReceiptAssetsToAssets(totalReceiptAssets());
    }

    /**
     * @notice Total amount of the receipt asset that is managed by the Portfolio.
     * @return Total amount of the receipt asset.
     */
    function totalReceiptAssets() public view returns (uint256) {
        return ERC20(receiptAsset).balanceOf(address(this));
    }

    /**
     * @notice Calculates the equivalent amount of assets for the given amount of receipt assets.
     * @param _receiptAssets Amount of receipt assets to convert.
     * @return Amount of assets.
     */
    function convertReceiptAssetsToAssets(uint256 _receiptAssets) public view virtual returns (uint256);

    /**
     * @notice Takes some amount of receipt assets from this portfolio as management fee.
     * @param _amountReceiptAssets Amount of receipt assets to take.
     */
    function takeFees(uint256 _amountReceiptAssets) external requiresAuth {
        ERC20(receiptAsset).safeTransfer(feeTreasury, _amountReceiptAssets);
        emit FeesTaken(_amountReceiptAssets);
    }

    /**
     * @notice Takes accrued percentage of assets from this portfolio as AUM fee.
     */
    function takeAumFees() public {
        if (didShutdown) return _takeAumFeesShutdown();
        uint256 _totalReceiptAssets = totalReceiptAssets();
        uint256 _period = block.timestamp - timestampAumFeesTaken;
        uint256 _feeAmount = _calculateAumFee(_totalReceiptAssets, _period);
        if (_feeAmount > _totalReceiptAssets) _feeAmount = _totalReceiptAssets;
        if (_feeAmount > 0 || totalSupply == 0) {
            // in either case, we want to set `timestampAumFeesTaken`...
            timestampAumFeesTaken = block.timestamp;
            // but we only want to transfer/emit on non-zero amount
            if (_feeAmount > 0) {
                ERC20(receiptAsset).safeTransfer(feeTreasury, _feeAmount);
                emit AumFeesTaken(_feeAmount, _period);
            }
        }
    }

    /**
     * @notice Takes accrued percentage of post-shutdown baseToken from this portfolio as AUM fee.
     */
    function _takeAumFeesShutdown() internal {
        uint256 _totalAssets = baseToken.balanceOf(address(this));
        uint256 _period = block.timestamp - timestampAumFeesTaken;
        uint256 _feeAmount = _calculateAumFee(_totalAssets, _period);
        if (_feeAmount > _totalAssets) _feeAmount = _totalAssets;
        // in `takeAumFees`, the following conditional checks totalSupply as well, solving a first deposit corner case.
        // In this case, we don't need to check, because deposits aren't allowed after shutdown.
        if (_feeAmount > 0) {
            timestampAumFeesTaken = block.timestamp;
            baseToken.safeTransfer(feeTreasury, _feeAmount);
            emit AumFeesTaken(_feeAmount, _period);
        }
    }

    /**
     * @notice Exchange `_amountBaseToken` for some amount of Portfolio shares.
     * @param _amountBaseToken The amount of the Entity's baseToken to deposit.
     * @param _data Data that the portfolio needs to make the deposit. In some cases, this will be swap parameters.
     * The first 32 bytes of this data should be the ABI-encoded `minSharesOut`.
     * @return shares The amount of shares that this deposit yields to the Entity.
     */
    function deposit(uint256 _amountBaseToken, bytes calldata _data) external nonReentrant returns (uint256) {
        // all portfolios should revert on deposit after shutdown
        if (didShutdown) revert DepositAfterShutdown();

        // all portfolios should revert on a deposit from a non-entity (or inactive one)
        if (!_isEntity(Entity(payable(msg.sender)))) revert NotEntity();

        // all portfolios should take AUM fees
        takeAumFees();

        // all portfolios should make a deposit
        // all transferring of baseToken and share calculation should occur inside _deposit
        (uint256 _shares, uint256 _assets, uint256 _fee) = _deposit(_amountBaseToken, _data);
        if (_shares < abi.decode(_data, (uint256))) revert Slippage();
        if (_shares == 0) revert RoundsToZero();

        // mint shares
        _mint(msg.sender, _shares);

        // and check cap
        _checkCap();

        // and emit an event
        emit Deposit(msg.sender, msg.sender, _assets, _shares, _amountBaseToken, _fee);
        return _shares;
    }

    /**
     * @notice Check to make sure the cap has not been exceeded.
     * @dev Most portfolios have the same asset and baseToken, so the _checkCap implementation here is written to accomodate
     * that situation. For portfolios where that is not the case, this method needs to be overwritten to ensure the cap
     * (denominated in baseToken) is properly compared to the number of assets.
     */
    function _checkCap() internal virtual {
        if (asset != address(baseToken)) revert BadCheckCapImplementation();
        if (totalAssets() > cap) revert ExceedsCap();
    }

    /**
     * @notice Exchange `_amountIn` for some amount of Portfolio shares.
     * @dev Should include the transferring of baseToken and conversion to shares.
     * @param _amountIn The amount of the Entity's baseToken to deposit.
     * @param _data Data that the portfolio needs to make the deposit. In some cases, this will be swap parameters.
     * @return shares The amount of shares that this deposit yields to the Entity.
     * @return assets The amount of assets that this deposit yields to the portfolio.
     * @return fee The baseToken fee that this deposit yields to the treasury.
     */
    function _deposit(uint256 _amountIn, bytes calldata _data)
        internal
        virtual
        returns (uint256 shares, uint256 assets, uint256 fee);

    /**
     * @notice Exchange `_amountShares` for some amount of baseToken.
     * @param _amountShares The amount of the Entity's portfolio shares to exchange.
     * @param _data Data that the portfolio needs to make the redemption. In some cases, this will be swap parameters.
     * @return baseTokenOut The amount of baseToken that this redemption yields to the Entity.
     */
    function redeem(uint256 _amountShares, bytes calldata _data) external nonReentrant returns (uint256 baseTokenOut) {
        takeAumFees();
        if (didShutdown) return _redeemShutdown(_amountShares);
        (uint256 _assetsOut, uint256 _baseTokenOut) = _redeem(_amountShares, _data);
        if (_assetsOut == 0) revert RoundsToZero();
        _burn(msg.sender, _amountShares);
        (uint256 _netAmount, uint256 _fee) = _calculateFee(_baseTokenOut, redemptionFee);
        baseToken.safeTransfer(feeTreasury, _fee);
        baseToken.safeTransfer(msg.sender, _netAmount);
        emit Redeem(msg.sender, msg.sender, _assetsOut, _amountShares, _netAmount, _fee);
        return _netAmount;
    }

    /**
     * @notice Exchange `_amountShares` for some amount of Portfolio assets.
     * @param _amountShares The amount of portfolio shares to exchange.
     * @param _data Data that the portfolio needs to redeem the assets. In some cases, this will be swap parameters.
     * @return assetsOut The amount of assets that this redemption yielded (and then converted to baseToken).
     * @return baseTokenOut Amount in baseToken to which these assets were converted.
     */
    function _redeem(uint256 _amountShares, bytes calldata _data)
        internal
        virtual
        returns (uint256 assetsOut, uint256 baseTokenOut);

    /**
     * @notice Handles redemption after shutdown, exchanging shares for baseToken.
     * @param _amountShares Shares being redeemed.
     * @return Amount of baseToken received.
     */
    function _redeemShutdown(uint256 _amountShares) internal returns (uint256) {
        uint256 _baseTokenOut = convertToAssetsShutdown(_amountShares);
        _burn(msg.sender, _amountShares);
        (uint256 _netAmount, uint256 _fee) = _calculateFee(_baseTokenOut, redemptionFee);
        baseToken.safeTransfer(feeTreasury, _fee);
        baseToken.safeTransfer(msg.sender, _netAmount);
        emit Redeem(msg.sender, msg.sender, _baseTokenOut, _amountShares, _netAmount, _fee);
        return _netAmount;
    }

    /**
     * @notice Calculates the amount of shares that the Portfolio should exchange for the amount of assets provided.
     * @param _assets Amount of assets.
     * @return Amount of shares.
     */
    function convertToShares(uint256 _assets) public view returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _assets : _assets.mulDivDown(_supply, totalAssets());
    }

    /**
     * @notice Calculates the amount of assets that the Portfolio should exchange for the amount of shares provided.
     * @param _shares Amount of shares.
     * @return Amount of assets.
     */
    function convertToAssets(uint256 _shares) public view returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _shares : _shares.mulDivDown(totalAssets(), _supply);
    }

    /**
     * @notice Calculates the amount of baseToken that the Portfolio should exchange for the amount of shares provided.
     * Used only if the Portfolio has shut down.
     * @dev Rounding down here favors the portfolio, so the user gets slightly less and the portfolio gets slightly more,
     * that way it prevents a situation where the user is owed x but the vault only has x - epsilon, where epsilon is
     * some tiny number due to rounding error.
     * @param _shares Amount of shares.
     * @return Amount of baseToken.
     */
    function convertToAssetsShutdown(uint256 _shares) public view returns (uint256) {
        uint256 _supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return _supply == 0 ? _shares : _shares.mulDivDown(baseToken.balanceOf(address(this)), _supply);
    }

    /**
     * @notice Exit out all assets of portfolio for baseToken. Must persist a mechanism for entities to redeem their shares for baseToken.
     * @param _data Data that the portfolio needs to exit from asset.  Consult the portfolio's `_exit` method to determine
     * the correct format for this data.
     * @return baseTokenOut The amount of baseToken that this exit yielded.
     */
    function shutdown(bytes calldata _data) external requiresAuth returns (uint256 baseTokenOut) {
        if (didShutdown) revert DidShutdown();
        didShutdown = true;
        uint256 _assetsOut = totalAssets();
        // In most cases, _actualAssetsOut will equal _assetsOut, but in SingleTokenPortfolio, it may be less.
        (uint256 _actualAssetsOut, uint256 _baseTokenOut) = _exit(_assetsOut, _data);
        emit Shutdown(_actualAssetsOut, _baseTokenOut);
        return _baseTokenOut;
    }

    /**
     * @notice Convert some amount of asset into baseToken, either partially or fully exiting the portfolio asset.
     * @dev This method is used in `redeem` and `shutdown` calls.
     * @param _amount The amount of the Entity's portfolio asset to exchange.
     * @param _data Data that the portfolio needs to exit from asset. In some cases, this will be swap parameters. Consult the portfolio's
     * `_exit` method to determine the correct format for this data.
     * @return actualAssetsOut The amount of assets that were exited. In most cases, this will be equal to `_amount`, but may differ
     * by some errorMarginPct in SingleTokenPortfolio.
     * @return baseTokenOut The amount of baseToken that this exit yielded.
     */
    function _exit(uint256 _amount, bytes calldata _data)
        internal
        virtual
        returns (uint256 actualAssetsOut, uint256 baseTokenOut);

    /// @notice `transfer` disabled on Portfolio tokens.
    function transfer(
        address, // to
        uint256 // amount
    ) public pure override returns (bool) {
        revert TransferDisallowed();
    }

    /// @notice `transferFrom` disabled on Portfolio tokens.
    function transferFrom(address, /* from */ address, /* to */ uint256 /* amount */ )
        public
        pure
        override
        returns (bool)
    {
        revert TransferDisallowed();
    }

    /// @notice `approve` disabled on Portfolio tokens.
    function approve(address, /* to */ uint256 /* amount */ ) public pure override returns (bool) {
        revert TransferDisallowed();
    }

    /// @notice `permit` disabled on Portfolio tokens.
    function permit(
        address, /* owner */
        address, /* spender */
        uint256, /* value */
        uint256, /* deadline */
        uint8, /* v */
        bytes32, /* r */
        bytes32 /* s */
    ) public pure override {
        revert TransferDisallowed();
    }

    /**
     * @notice Permissioned method that allows Endaoment admin to make arbitrary calls acting as this Portfolio.
     * @param _target The address to which the call will be made.
     * @param _value The ETH value that should be forwarded with the call.
     * @param _data The calldata that will be sent with the call.
     * @return _return The data returned by the call.
     */
    function callAsPortfolio(address _target, uint256 _value, bytes memory _data)
        external
        payable
        requiresAuth
        returns (bytes memory)
    {
        (bool _success, bytes memory _response) = payable(_target).call{value: _value}(_data);
        if (!_success) revert CallFailed(_response);
        return _response;
    }

    /**
     * @notice Internal helper method to calculate the fee on a base token amount for a given fee multiplier.
     * @param _amount Amount of baseToken.
     * @param _feeMultiplier Multiplier (as zoc) to apply to the amount.
     * @return _netAmount The amount of baseToken after the fee is applied.
     * @return _fee The amount of baseToken to be taken as a fee.
     */
    function _calculateFee(uint256 _amount, uint256 _feeMultiplier)
        internal
        pure
        returns (uint256 _netAmount, uint256 _fee)
    {
        if (_feeMultiplier > Math.ZOC) revert PercentageOver100();
        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            _fee = _amount.zocmul(_feeMultiplier);
            // unchecked as the _feeMultiplier check with revert above protects against overflow
            _netAmount = _amount - _fee;
        }
    }

    /**
     * @notice Helper method to calculate AUM fee based on assets and time elapsed.
     * @param _totalAssets Assets over which to calculate AUM fee.
     * @param _period Seconds elapsed since AUM fee was last taken.
     * @dev We chose to calculate using simple interest rather than compound interest because the error was small and
     * simple interest is easier to calculate, reason about, and test.
     * @return _aumFee The amount of baseToken to be taken as AUM fee.
     */
    function _calculateAumFee(uint256 _totalAssets, uint256 _period) internal view returns (uint256) {
        if (_totalAssets == 0 || aumRate == 0 || _period == 0) return 0;
        // _period * aumRate is safe; max expected aum rate * 10 years of seconds is just over 1 WAD
        return _totalAssets.mulWadDown(_period * aumRate);
    }
}
