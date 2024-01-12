// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./MultipleTransitToken.sol";
import "./OnlySourceFunctionality.sol";

error DifferentAmountSpent();

contract RubicLiFiProxy is MultipleTransitToken, OnlySourceFunctionality {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public LifiDiamond;

    constructor(
        uint256 _fixedCryptoFee,
        address[] memory _routers,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts,
        uint256 _RubicPlatformFee,
        address _lifiDiamond
    ) {
        initialize(
            _fixedCryptoFee,
            _routers,
            _tokens,
            _minTokenAmounts,
            _maxTokenAmounts,
            _RubicPlatformFee,
            _lifiDiamond
        );
    }

    function initialize(
        uint256 _fixedCryptoFee,
        address[] memory _routers,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts,
        uint256 _RubicPlatformFee,
        address _lifiDiamond
    ) private initializer {
        __BridgeBaseInit(_fixedCryptoFee, _routers);
        __MultipleTransitTokenInitUnchained(_tokens, _minTokenAmounts, _maxTokenAmounts);

        __OnlySourceFunctionalityInitUnchained(_RubicPlatformFee);

        LifiDiamond = _lifiDiamond;

        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function lifiCall(BaseCrossChainParams calldata _params, bytes calldata _data)
        external
        payable
        nonReentrant
        whenNotPaused
        EventEmitter(_params)
    {
        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        accrueFixedCryptoFee(_params.integrator, _info); // collect fixed fee
        IERC20Upgradeable(_params.srcInputToken).safeTransferFrom(msg.sender, address(this), _params.srcInputAmount);

        uint256 _amountIn = accrueTokenFees(
            _params.integrator,
            _info,
            _params.srcInputAmount,
            0,
            _params.srcInputToken
        );

        smartApprove(_params.srcInputToken, _params.srcInputAmount, LifiDiamond);

        uint256 balanceBefore = IERC20Upgradeable(_params.srcInputToken).balanceOf(address(this));

        AddressUpgradeable.functionCall(LifiDiamond, _data);

        if (balanceBefore - IERC20Upgradeable(_params.srcInputToken).balanceOf(address(this)) != _amountIn) {
            revert DifferentAmountSpent();
        }
    }

    function lifiCallWithNative(BaseCrossChainParams calldata _params, bytes calldata _data)
        external
        payable
        nonReentrant
        whenNotPaused
        EventEmitter(_params)
    {
        uint256 _amountIn = accrueTokenFees(
            _params.integrator,
            integratorToFeeInfo[_params.integrator],
            msg.value - accrueFixedCryptoFee(_params.integrator, integratorToFeeInfo[_params.integrator]), // amountIn - fixedFee - commission
            0,
            address(0)
        );

        AddressUpgradeable.functionCallWithValue(LifiDiamond, _data, _amountIn);
    }

    function _calculateFee(
        IntegratorFeeInfo memory _info,
        uint256 _amountWithFee,
        uint256
    ) internal view override(BridgeBase, OnlySourceFunctionality) returns (uint256 _totalFee, uint256 _RubicFee) {
        (_totalFee, _RubicFee) = OnlySourceFunctionality._calculateFee(_info, _amountWithFee, 0);
    }

    function setLifiDiamond(address _lifiDiamond) external onlyManagerAndAdmin {
        LifiDiamond = _lifiDiamond;
    }

    function sweepTokens(address _token, uint256 _amount) external onlyManagerAndAdmin {
        _sendToken(_token, _amount, msg.sender);
    }
}
