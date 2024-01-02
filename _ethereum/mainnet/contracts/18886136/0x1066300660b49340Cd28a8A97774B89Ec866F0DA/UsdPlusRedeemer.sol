// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import "./UUPSUpgradeable.sol";
import {AccessControlDefaultAdminRulesUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./AggregatorV3Interface.sol";

import "./IUsdPlusRedeemer.sol";
import "./UsdPlus.sol";
import "./StakedUsdPlus.sol";

/// @notice manages requests for USD+ burning
/// @author Dinari (https://github.com/dinaricrypto/usdplus-contracts/blob/main/src/Redeemer.sol)
contract UsdPlusRedeemer is IUsdPlusRedeemer, UUPSUpgradeable, AccessControlDefaultAdminRulesUpgradeable {
    /// ------------------ Types ------------------
    using SafeERC20 for IERC20;
    using SafeERC20 for UsdPlus;

    error ZeroAddress();
    error ZeroAmount();

    bytes32 public constant FULFILLER_ROLE = keccak256("FULFILLER_ROLE");

    /// ------------------ Storage ------------------

    struct UsdPlusRedeemerStorage {
        // USD+
        UsdPlus _usdplus;
        // stUSD+
        StakedUsdPlus _stakedUsdplus;
        // is this payment token accepted?
        mapping(IERC20 => AggregatorV3Interface) _paymentTokenOracle;
        // request ticket => request
        mapping(uint256 => Request) _requests;
        // next request ticket number
        uint256 _nextTicket;
    }

    // keccak256(abi.encode(uint256(keccak256("dinaricrypto.storage.UsdPlusRedeemer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant USDPLUSREDEEMER_STORAGE_LOCATION =
        0xf724d8e1327974c3212114feec241a18ecc4f13b9dce5898792083418cd99000;

    function _getUsdPlusRedeemerStorage() private pure returns (UsdPlusRedeemerStorage storage $) {
        assembly {
            $.slot := USDPLUSREDEEMER_STORAGE_LOCATION
        }
    }

    /// ------------------ Initialization ------------------

    function initialize(StakedUsdPlus initialStakedUsdplus, address initialOwner) public initializer {
        __AccessControlDefaultAdminRules_init_unchained(0, initialOwner);

        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        $._usdplus = UsdPlus(initialStakedUsdplus.asset());
        $._stakedUsdplus = initialStakedUsdplus;
        $._nextTicket = 0;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// ------------------ Getters ------------------

    /// @inheritdoc IUsdPlusRedeemer
    function usdplus() external view returns (UsdPlus) {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        return $._usdplus;
    }

    /// @inheritdoc IUsdPlusRedeemer
    function stakedUsdplus() external view returns (StakedUsdPlus) {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        return $._stakedUsdplus;
    }

    /// @inheritdoc IUsdPlusRedeemer
    function paymentTokenOracle(IERC20 paymentToken) external view returns (AggregatorV3Interface) {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        return $._paymentTokenOracle[paymentToken];
    }

    /// @inheritdoc IUsdPlusRedeemer
    function requests(uint256 ticket) external view returns (Request memory) {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        return $._requests[ticket];
    }

    /// @inheritdoc IUsdPlusRedeemer
    function nextTicket() external view returns (uint256) {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        return $._nextTicket;
    }

    /// ------------------ Admin ------------------

    /// @notice set payment token oracle
    /// @param payment payment token
    /// @param oracle oracle
    function setPaymentTokenOracle(IERC20 payment, AggregatorV3Interface oracle)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        $._paymentTokenOracle[payment] = oracle;
        emit PaymentTokenOracleSet(payment, oracle);
    }

    // ----------------- Requests -----------------

    /// @inheritdoc IUsdPlusRedeemer
    function getOraclePrice(IERC20 paymentToken) public view returns (uint256, uint8) {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        AggregatorV3Interface oracle = $._paymentTokenOracle[paymentToken];
        if (address(oracle) == address(0)) revert PaymentTokenNotAccepted();

        // slither-disable-next-line unused-return
        (, int256 price,,,) = oracle.latestRoundData();
        uint8 oracleDecimals = oracle.decimals();

        return (uint256(price), oracleDecimals);
    }

    /// @inheritdoc IUsdPlusRedeemer
    function previewWithdraw(IERC20 paymentToken, uint256 paymentTokenAmount) public view returns (uint256) {
        (uint256 price, uint8 oracleDecimals) = getOraclePrice(paymentToken);
        return Math.mulDiv(paymentTokenAmount, price, 10 ** uint256(oracleDecimals), Math.Rounding.Ceil);
    }

    /// @inheritdoc IUsdPlusRedeemer
    function requestWithdraw(IERC20 paymentToken, uint256 paymentTokenAmount, address receiver, address owner)
        public
        returns (uint256 ticket)
    {
        if (receiver == address(0)) revert ZeroAddress();
        if (paymentTokenAmount == 0) revert ZeroAmount();

        uint256 usdplusAmount = previewWithdraw(paymentToken, paymentTokenAmount);
        if (usdplusAmount == 0) revert ZeroAmount();

        return _request(paymentToken, paymentTokenAmount, usdplusAmount, receiver, owner);
    }

    function _request(
        IERC20 paymentToken,
        uint256 paymentTokenAmount,
        uint256 usdplusAmount,
        address receiver,
        address owner
    ) internal returns (uint256 ticket) {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();

        unchecked {
            ticket = $._nextTicket++;
        }

        $._requests[ticket] = Request({
            owner: owner == address(this) ? msg.sender : owner,
            receiver: receiver,
            paymentToken: paymentToken,
            paymentTokenAmount: paymentTokenAmount,
            usdplusAmount: usdplusAmount
        });

        emit RequestCreated(ticket, receiver, paymentToken, paymentTokenAmount, usdplusAmount);

        if (owner != address(this)) {
            $._usdplus.safeTransferFrom(owner, address(this), usdplusAmount);
        }
    }

    /// @inheritdoc IUsdPlusRedeemer
    function previewRedeem(IERC20 paymentToken, uint256 usdplusAmount) public view returns (uint256) {
        (uint256 price, uint8 oracleDecimals) = getOraclePrice(paymentToken);
        return Math.mulDiv(usdplusAmount, 10 ** uint256(oracleDecimals), price, Math.Rounding.Floor);
    }

    /// @inheritdoc IUsdPlusRedeemer
    function requestRedeem(IERC20 paymentToken, uint256 usdplusAmount, address receiver, address owner)
        public
        returns (uint256 ticket)
    {
        if (receiver == address(0)) revert ZeroAddress();
        if (usdplusAmount == 0) revert ZeroAmount();

        uint256 paymentTokenAmount = previewRedeem(paymentToken, usdplusAmount);
        if (paymentTokenAmount == 0) revert ZeroAmount();

        return _request(paymentToken, paymentTokenAmount, usdplusAmount, receiver, owner);
    }

    /// @inheritdoc IUsdPlusRedeemer
    function previewUnstakeAndRedeem(IERC20 paymentToken, uint256 stakedUsdplusAmount)
        external
        view
        returns (uint256)
    {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        return previewRedeem(paymentToken, $._stakedUsdplus.previewRedeem(stakedUsdplusAmount));
    }

    /// @inheritdoc IUsdPlusRedeemer
    function unstakeAndRequestRedeem(IERC20 paymentToken, uint256 stakedUsdplusAmount, address receiver, address owner)
        external
        returns (uint256 ticket)
    {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        uint256 usdplusAmount = $._stakedUsdplus.redeem(stakedUsdplusAmount, address(this), owner);
        return requestRedeem(paymentToken, usdplusAmount, receiver, address(this));
    }

    /// @inheritdoc IUsdPlusRedeemer
    function fulfill(uint256 ticket) external onlyRole(FULFILLER_ROLE) {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        Request memory request = $._requests[ticket];

        if (request.receiver == address(0)) revert InvalidTicket();

        delete $._requests[ticket];

        emit RequestFulfilled(
            ticket, request.receiver, request.paymentToken, request.paymentTokenAmount, request.usdplusAmount
        );

        $._usdplus.burn(request.owner, request.usdplusAmount);
        request.paymentToken.safeTransferFrom(msg.sender, request.receiver, request.paymentTokenAmount);
    }

    /// @inheritdoc IUsdPlusRedeemer
    function cancel(uint256 ticket) external onlyRole(FULFILLER_ROLE) {
        UsdPlusRedeemerStorage storage $ = _getUsdPlusRedeemerStorage();
        Request memory request = $._requests[ticket];

        if (request.receiver == address(0)) revert InvalidTicket();

        delete $._requests[ticket];

        emit RequestCancelled(ticket, request.receiver);

        // return USD+ to requester
        $._usdplus.safeTransfer(request.owner, request.usdplusAmount);
    }
}
