// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import "./UUPSUpgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./AggregatorV3Interface.sol";

import "./IUsdPlusMinter.sol";
import "./UsdPlus.sol";
import "./StakedUsdPlus.sol";

/// @notice USD+ minter
/// @author Dinari (https://github.com/dinaricrypto/usdplus-contracts/blob/main/src/Minter.sol)
contract UsdPlusMinter is IUsdPlusMinter, UUPSUpgradeable, Ownable2StepUpgradeable {
    /// ------------------ Types ------------------
    using SafeERC20 for IERC20;
    using SafeERC20 for UsdPlus;

    error ZeroAddress();
    error ZeroAmount();

    /// ------------------ Storage ------------------

    struct UsdPlusMinterStorage {
        // USD+
        UsdPlus _usdplus;
        // stUSD+
        StakedUsdPlus _stakedUsdplus;
        // receiver of payment tokens
        address _paymentRecipient;
        // is this payment token accepted?
        mapping(IERC20 => AggregatorV3Interface) _paymentTokenOracle;
    }

    // keccak256(abi.encode(uint256(keccak256("dinaricrypto.storage.UsdPlusMinter")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant USDPLUSMINTER_STORAGE_LOCATION =
        0xf45ed6bde210b9a0bc6994d3da3a58de9b4dab28125cb5a4981ed369bf01bc00;

    function _getUsdPlusMinterStorage() private pure returns (UsdPlusMinterStorage storage $) {
        assembly {
            $.slot := USDPLUSMINTER_STORAGE_LOCATION
        }
    }

    /// ------------------ Initialization ------------------

    function initialize(StakedUsdPlus initialStakedUsdplus, address initialPaymentRecipient, address initialOwner)
        public
        initializer
    {
        if (initialPaymentRecipient == address(0)) revert ZeroAddress();

        __Ownable_init(initialOwner);

        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        $._usdplus = UsdPlus(initialStakedUsdplus.asset());
        $._stakedUsdplus = initialStakedUsdplus;
        $._paymentRecipient = initialPaymentRecipient;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// ------------------ Getters ------------------

    /// @inheritdoc IUsdPlusMinter
    function usdplus() external view returns (UsdPlus) {
        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        return $._usdplus;
    }

    /// @inheritdoc IUsdPlusMinter
    function stakedUsdplus() external view returns (StakedUsdPlus) {
        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        return $._stakedUsdplus;
    }

    /// @inheritdoc IUsdPlusMinter
    function paymentRecipient() external view returns (address) {
        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        return $._paymentRecipient;
    }

    /// @inheritdoc IUsdPlusMinter
    function paymentTokenOracle(IERC20 paymentToken) external view returns (AggregatorV3Interface) {
        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        return $._paymentTokenOracle[paymentToken];
    }

    /// ------------------ Admin ------------------

    /// @notice set payment recipient
    function setPaymentRecipient(address newPaymentRecipient) external onlyOwner {
        if (newPaymentRecipient == address(0)) revert ZeroAddress();

        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        $._paymentRecipient = newPaymentRecipient;
        emit PaymentRecipientSet(newPaymentRecipient);
    }

    /// @notice set payment token oracle
    /// @param paymentToken payment token
    /// @param oracle oracle
    function setPaymentTokenOracle(IERC20 paymentToken, AggregatorV3Interface oracle) external onlyOwner {
        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        $._paymentTokenOracle[paymentToken] = oracle;
        emit PaymentTokenOracleSet(paymentToken, oracle);
    }

    // ------------------ Mint ------------------

    /// @inheritdoc IUsdPlusMinter
    function getOraclePrice(IERC20 paymentToken) public view returns (uint256, uint8) {
        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        AggregatorV3Interface oracle = $._paymentTokenOracle[paymentToken];
        if (address(oracle) == address(0)) revert PaymentTokenNotAccepted();

        // slither-disable-next-line unused-return
        (, int256 price,,,) = oracle.latestRoundData();
        uint8 oracleDecimals = oracle.decimals();

        return (uint256(price), oracleDecimals);
    }

    /// @inheritdoc IUsdPlusMinter
    function previewDeposit(IERC20 paymentToken, uint256 paymentTokenAmount) public view returns (uint256) {
        (uint256 price, uint8 oracleDecimals) = getOraclePrice(paymentToken);
        return Math.mulDiv(paymentTokenAmount, price, 10 ** uint256(oracleDecimals), Math.Rounding.Floor);
    }

    /// @inheritdoc IUsdPlusMinter
    function deposit(IERC20 paymentToken, uint256 paymentTokenAmount, address receiver)
        public
        returns (uint256 usdPlusAmount)
    {
        if (receiver == address(0)) revert ZeroAddress();
        if (paymentTokenAmount == 0) revert ZeroAmount();

        usdPlusAmount = previewDeposit(paymentToken, paymentTokenAmount);
        if (usdPlusAmount == 0) revert ZeroAmount();

        _issue(paymentToken, paymentTokenAmount, usdPlusAmount, receiver);
    }

    function _issue(IERC20 paymentToken, uint256 paymentTokenAmount, uint256 usdPlusAmount, address receiver)
        internal
    {
        emit Issued(receiver, paymentToken, paymentTokenAmount, usdPlusAmount);

        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        paymentToken.safeTransferFrom(msg.sender, $._paymentRecipient, paymentTokenAmount);
        $._usdplus.mint(receiver, usdPlusAmount);
    }

    /// @inheritdoc IUsdPlusMinter
    function previewDepositAndStake(IERC20 paymentToken, uint256 paymentTokenAmount) external view returns (uint256) {
        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        return $._stakedUsdplus.previewDeposit(previewDeposit(paymentToken, paymentTokenAmount));
    }

    /// @inheritdoc IUsdPlusMinter
    function depositAndStake(IERC20 paymentToken, uint256 paymentTokenAmount, address receiver)
        external
        returns (uint256)
    {
        uint256 _issueAmount = deposit(paymentToken, paymentTokenAmount, address(this));
        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        StakedUsdPlus _stakedUsdplus = $._stakedUsdplus;
        $._usdplus.safeIncreaseAllowance(address(_stakedUsdplus), _issueAmount);
        return _stakedUsdplus.deposit(_issueAmount, receiver);
    }

    /// @inheritdoc IUsdPlusMinter
    function previewMint(IERC20 paymentToken, uint256 usdPlusAmount) public view returns (uint256) {
        (uint256 price, uint8 oracleDecimals) = getOraclePrice(paymentToken);
        return Math.mulDiv(usdPlusAmount, 10 ** uint256(oracleDecimals), price, Math.Rounding.Ceil);
    }

    /// @inheritdoc IUsdPlusMinter
    function mint(IERC20 paymentToken, uint256 usdPlusAmount, address receiver)
        public
        returns (uint256 paymentTokenAmount)
    {
        if (receiver == address(0)) revert ZeroAddress();
        if (usdPlusAmount == 0) revert ZeroAmount();

        paymentTokenAmount = previewMint(paymentToken, usdPlusAmount);
        if (paymentTokenAmount == 0) revert ZeroAmount();

        _issue(paymentToken, paymentTokenAmount, usdPlusAmount, receiver);
    }

    /// @inheritdoc IUsdPlusMinter
    function mintAndStake(IERC20 paymentToken, uint256 usdPlusAmount, address receiver) external returns (uint256) {
        mint(paymentToken, usdPlusAmount, address(this));
        UsdPlusMinterStorage storage $ = _getUsdPlusMinterStorage();
        StakedUsdPlus _stakedUsdplus = $._stakedUsdplus;
        $._usdplus.safeIncreaseAllowance(address(_stakedUsdplus), usdPlusAmount);
        return _stakedUsdplus.deposit(usdPlusAmount, receiver);
    }
}
