// SPDX-License-Identifier: GNU LGPLv3
// Heavily inspired from CompoundLeverage strategy of Yearn. https://etherscan.io/address/0x4031afd3B0F71Bace9181E554A9E680Ee4AbE7dF#code

pragma solidity 0.8.3;

import "./Strategy.sol";
import "./ICompound.sol";
import "./IUniswapV3Oracle.sol";
import "./FlashLoanHelper.sol";

/// @title This strategy will deposit collateral token in Compound and based on position
/// it will borrow same collateral token. It will use borrowed asset as supply and borrow again.
abstract contract CompoundLeverageStrategy is Strategy, FlashLoanHelper {
    using SafeERC20 for IERC20;

    uint256 internal constant MAX_BPS = 10_000; //100%
    uint256 public minBorrowLimit = 7_000; // 70%
    uint256 public maxBorrowLimit = 9_000; // 90%
    CToken internal cToken;
    address internal constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    Comptroller internal constant COMPTROLLER = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    IUniswapV3Oracle internal constant ORACLE = IUniswapV3Oracle(0x0F1f5A87f99f0918e6C81F16E59F3518698221Ff);
    uint32 internal constant TWAP_PERIOD = 3600;

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) Strategy(_pool, _swapManager, _receiptToken) {
        require(_receiptToken != address(0), "cToken-address-is-zero");
        cToken = CToken(_receiptToken);
    }

    /**
     * @notice Update upper and lower borrow limit
     * @dev It is possible to set 0 as _minBorrowLimit to not borrow anything
     * @param _minBorrowLimit Minimum % we want to borrow
     * @param _maxBorrowLimit Maximum % we want to borrow
     */
    function updateBorrowLimit(uint256 _minBorrowLimit, uint256 _maxBorrowLimit) external onlyGovernor {
        require(_maxBorrowLimit < MAX_BPS, "invalid-max-borrow-limit");
        require(_maxBorrowLimit > _minBorrowLimit, "max-should-be-higher-than-min");
        minBorrowLimit = _minBorrowLimit;
        maxBorrowLimit = _maxBorrowLimit;
    }

    function updateAaveStatus(bool _status) external onlyGovernor {
        _updateAaveStatus(_status);
    }

    function updateDyDxStatus(bool _status) external onlyGovernor {
        _updateDyDxStatus(_status, address(collateralToken));
    }

    /**
     * @notice Calculate total value based on COMP claimed, supply and borrow position
     * @dev Report total value in collateral token
     * @dev Claimed COMP will stay in strategy until next rebalance
     */
    function totalValueCurrent() external override returns (uint256 _totalValue) {
        cToken.exchangeRateCurrent();
        _claimComp();
        _totalValue = _calculateTotalValue(IERC20(COMP).balanceOf(address(this)));
    }

    /**
     * @notice Calculate and return borrow ratio range.
     * @dev It is calculated as collateralFactor * borrowLimit
     */
    function borrowRatioRange() public view returns (uint256 _minBorrowRatio, uint256 _maxBorrowRatio) {
        (, uint256 _collateralFactor, ) = COMPTROLLER.markets(address(cToken));
        _minBorrowRatio = (minBorrowLimit * _collateralFactor) / 1e18;
        _maxBorrowRatio = (maxBorrowLimit * _collateralFactor) / 1e18;
    }

    /**
     * @notice Current borrow ratio, calculated as current borrow divide by max allowed borrow
     * Return value is based on basis points, i.e. 7500 = 75% ratio
     */
    function currentBorrowRatio() external view returns (uint256) {
        (uint256 _supply, uint256 _borrow) = getPosition();
        return _borrow == 0 ? 0 : (_borrow * MAX_BPS) / _supply;
    }

    /**
     * @notice Calculate total value using COMP accrued, supply and borrow position
     * @dev Compound calculate COMP accrued and store it when user interact with
     * Compound contracts, i.e. deposit, withdraw or transfer tokens.
     * So compAccrued() will return stored COMP accrued amount, which is older
     * @dev For up to date value check totalValueCurrent()
     */
    function totalValue() public view virtual override returns (uint256 _totalValue) {
        _totalValue = _calculateTotalValue(COMPTROLLER.compAccrued(address(this)));
    }

    /**
     * @notice Calculate current position using claimed COMP and current borrow.
     */
    function isLossMaking() external returns (bool) {
        _claimComp();
        (, uint256 _compAsCollateral, ) =
            swapManager.bestOutputFixedInput(COMP, address(collateralToken), IERC20(COMP).balanceOf(address(this)));

        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        (uint256 _supply, uint256 _borrow) = getPosition();
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _collateralHere + _compAsCollateral + _supply - _borrow;
        return _totalCollateral < _totalDebt;
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == address(cToken) || _token == COMP || _token == address(collateralToken);
    }

    /// @notice Return supply and borrow position. Position may return few block old value
    function getPosition() public view returns (uint256 _supply, uint256 _borrow) {
        (, uint256 _cTokenBalance, uint256 _borrowBalance, uint256 _exchangeRate) =
            cToken.getAccountSnapshot(address(this));
        _supply = (_cTokenBalance * _exchangeRate) / 1e18;
        _borrow = _borrowBalance;
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(cToken), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(COMP).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
        FlashLoanHelper._approveToken(address(collateralToken), _amount);
    }

    /**
     * @notice Claim COMP and transfer to new strategy
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        require(IStrategy(_newStrategy).token() == address(cToken), "wrong-receipt-token");
        minBorrowLimit = 0;
        // It will calculate amount to repay based on borrow limit and payback all
        _reinvest();
    }

    /**
     * @notice Calculate borrow position based on borrow ratio, current supply, borrow, amount
     * being deposited or withdrawn.
     * @param _amount Collateral amount
     * @param _isDeposit Flag indicating whether we are depositing _amount or withdrawing
     * @return _position Amount of borrow that need to be adjusted
     * @return _shouldRepay Flag indicating whether _position is borrow amount or repay amount
     */
    function _calculateDesiredPosition(uint256 _amount, bool _isDeposit)
        internal
        returns (uint256 _position, bool _shouldRepay)
    {
        uint256 _totalSupply = cToken.balanceOfUnderlying(address(this));
        uint256 _currentBorrow = cToken.borrowBalanceStored(address(this));
        // If minimum borrow limit set to 0 then repay borrow
        if (minBorrowLimit == 0) {
            return (_currentBorrow, true);
        }

        uint256 _supply = _totalSupply - _currentBorrow;

        // In case of withdraw, _amount can be greater than _supply
        uint256 _newSupply = _isDeposit ? _supply + _amount : _supply > _amount ? _supply - _amount : 0;

        (uint256 _minBorrowRatio, uint256 _maxBorrowRatio) = borrowRatioRange();
        // (supply * borrowRatio)/(BPS - borrowRatio)
        uint256 _borrowUpperBound = (_newSupply * _maxBorrowRatio) / (MAX_BPS - _maxBorrowRatio);
        uint256 _borrowLowerBound = (_newSupply * _minBorrowRatio) / (MAX_BPS - _minBorrowRatio);

        // If our current borrow is greater than max borrow allowed, then we will have to repay
        // some to achieve safe position else borrow more.
        if (_currentBorrow > _borrowUpperBound) {
            _shouldRepay = true;
            // If borrow > upperBound then it is greater than lowerBound too.
            _position = _currentBorrow - _borrowLowerBound;
        } else if (_currentBorrow < _borrowLowerBound) {
            _shouldRepay = false;
            // We can borrow more.
            _position = _borrowLowerBound - _currentBorrow;
        }
    }

    /**
     * @dev COMP is converted to collateral and if we have some borrow interest to pay,
     * it will go come from collateral.
     * @dev Report total value in collateral token
     */
    function _calculateTotalValue(uint256 _compAccrued) internal view returns (uint256 _totalValue) {
        uint256 _compAsCollateral;
        if (_compAccrued != 0) {
            (, _compAsCollateral, ) = swapManager.bestOutputFixedInput(COMP, address(collateralToken), _compAccrued);
        }
        (uint256 _supply, uint256 _borrow) = getPosition();
        _totalValue = _compAsCollateral + collateralToken.balanceOf(address(this)) + _supply - _borrow;
    }

    /// @notice Claim comp
    function _claimComp() internal {
        address[] memory _markets = new address[](1);
        _markets[0] = address(cToken);
        COMPTROLLER.claimComp(address(this), _markets);
    }

    /// @notice Claim COMP and convert COMP into collateral token.
    function _claimRewardsAndConvertTo(address _toToken) internal override {
        _claimComp();
        uint256 _compAmount = IERC20(COMP).balanceOf(address(this));
        if (_compAmount != 0) {
            _safeSwap(COMP, _toToken, _compAmount);
        }
    }

    /**
     * @notice Generate report for pools accounting and also send profit and any payback to pool.
     * @dev Claim COMP and convert to collateral.
     */
    function _generateReport()
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        // Claim COMP and convert to collateral token
        _claimRewardsAndConvertTo(address(collateralToken));

        uint256 _supply = cToken.balanceOfUnderlying(address(this));
        uint256 _borrow = cToken.borrowBalanceStored(address(this));
        uint256 _investedCollateral = _supply - _borrow;

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _investedCollateral + _collateralHere;

        uint256 _profitToWithdraw;

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
            if (_collateralHere <= _profit) {
                _profitToWithdraw = _profit - _collateralHere;
            } else if (_collateralHere >= (_profit + _excessDebt)) {
                // Very rare scenario
                _payback = _excessDebt;
            } else {
                // _profit < CollateralHere < _profit + _excessDebt
                _payback = _collateralHere - _profit;
            }
        } else {
            _loss = _totalDebt - _totalCollateral;
        }

        uint256 _paybackToWithdraw = _excessDebt - _payback;
        uint256 _totalAmountToWithdraw = _paybackToWithdraw + _profitToWithdraw;
        if (_totalAmountToWithdraw != 0) {
            uint256 _withdrawn = _withdrawHere(_totalAmountToWithdraw);
            // Any amount withdrawn over _profitToWithdraw is payback for pool
            if (_withdrawn > _profitToWithdraw) {
                _payback += (_withdrawn - _profitToWithdraw);
            }
        }
    }

    /**
     *  Adjust position by normal leverage and deleverage.
     * @param _adjustBy Amount by which we want to increase or decrease _borrow
     * @param _shouldRepay True indicate we want to deleverage
     * @return amount Actual adjusted amount
     */
    function _adjustPosition(uint256 _adjustBy, bool _shouldRepay) internal returns (uint256 amount) {
        // We can get position via view function, as this function will be called after _calculateDesiredPosition
        (uint256 _supply, uint256 _borrow) = getPosition();

        // If no borrow then there is nothing to deleverage
        if (_borrow == 0 && _shouldRepay) {
            return 0;
        }

        (, uint256 collateralFactor, ) = COMPTROLLER.markets(address(cToken));

        if (_shouldRepay) {
            amount = _normalDeleverage(_adjustBy, _supply, _borrow, collateralFactor);
        } else {
            amount = _normalLeverage(_adjustBy, _supply, _borrow, collateralFactor);
        }
    }

    /**
     * Deleverage: Reduce borrow to achieve safe position
     * @param _maxDeleverage Reduce borrow by this amount
     * @return _deleveragedAmount Amount we actually reduced
     */
    function _normalDeleverage(
        uint256 _maxDeleverage,
        uint256 _supply,
        uint256 _borrow,
        uint256 _collateralFactor
    ) internal returns (uint256 _deleveragedAmount) {
        uint256 _theoreticalSupply;

        if (_collateralFactor != 0) {
            // Calculate minimum supply required to support _borrow
            _theoreticalSupply = (_borrow * 1e18) / _collateralFactor;
        }

        _deleveragedAmount = _supply - _theoreticalSupply;

        if (_deleveragedAmount >= _borrow) {
            _deleveragedAmount = _borrow;
        }
        if (_deleveragedAmount >= _maxDeleverage) {
            _deleveragedAmount = _maxDeleverage;
        }

        _redeemUnderlying(_deleveragedAmount);
        _repayBorrow(_deleveragedAmount);
    }

    /**
     * Leverage: Borrow more
     * @param _maxLeverage Max amount to borrow
     * @return _leveragedAmount Amount we actually borrowed
     */
    function _normalLeverage(
        uint256 _maxLeverage,
        uint256 _supply,
        uint256 _borrow,
        uint256 _collateralFactor
    ) internal returns (uint256 _leveragedAmount) {
        // Calculate maximum we can borrow at current _supply
        uint256 theoreticalBorrow = (_supply * _collateralFactor) / 1e18;

        _leveragedAmount = theoreticalBorrow - _borrow;

        if (_leveragedAmount >= _maxLeverage) {
            _leveragedAmount = _maxLeverage;
        }
        _borrowCollateral(_leveragedAmount);
        _mint(collateralToken.balanceOf(address(this)));
    }

    /// @notice Deposit collateral in Compound and adjust borrow position
    function _reinvest() internal virtual override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        (uint256 _position, bool _shouldRepay) = _calculateDesiredPosition(_collateralBalance, true);
        // Supply collateral to compound.
        _mint(_collateralBalance);

        // During reinvest, _shouldRepay will be false which indicate that we will borrow more.
        // Due to more fee Aave flash loan is not used for borrow
        if (isDyDxActive && _position > 0) {
            bytes memory _data = abi.encode(_position, _shouldRepay);
            _position -= _doDyDxFlashLoan(address(collateralToken), _position, _data);
        }

        uint256 i = 0;
        while (_position > 0 && i <= 6) {
            _position -= _adjustPosition(_position, _shouldRepay);
            i++;
        }
    }

    /// @dev Withdraw collateral and transfer it to pool
    function _withdraw(uint256 _amount) internal override {
        collateralToken.safeTransfer(pool, _withdrawHere(_amount));
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 _amount) internal returns (uint256) {
        (uint256 _position, bool _shouldRepay) = _calculateDesiredPosition(_amount, false);
        if (_shouldRepay) {
            // Due to less fee DyDx is our primary flash loan provider
            if (isDyDxActive) {
                bytes memory _data = abi.encode(_position, _shouldRepay);
                _position -= _doDyDxFlashLoan(address(collateralToken), _position, _data);
            }
            // Do aave flash loan if needed
            if (_position > 0 && isAaveActive) {
                bytes memory _data = abi.encode(_position, _shouldRepay);
                _position -= _doAaveFlashLoan(address(collateralToken), _position, _data);
            }

            // If we still have _position to deleverage do it via normal deleverage
            uint256 i = 0;
            while (_position > 0 && i <= 10) {
                _position -= _adjustPosition(_position, true);
                i++;
            }

            // There may be scenario where we are not able to deleverage enough
            if (_position != 0) {
                // Calculate redeemable at current borrow and supply.
                (uint256 _supply, uint256 _borrow) = getPosition();
                (, uint256 _maxBorrowRatio) = borrowRatioRange();
                uint256 _supplyToSupportBorrow;
                if (_maxBorrowRatio != 0) {
                    _supplyToSupportBorrow = (_borrow * MAX_BPS) / _maxBorrowRatio;
                }
                // Current supply minus supply required to support _borrow at _maxBorrowRatio
                uint256 _redeemable = _supply - _supplyToSupportBorrow;
                if (_amount > _redeemable) {
                    _amount = _redeemable;
                }
            }
        }
        uint256 _collateralBefore = collateralToken.balanceOf(address(this));

        // If we do not have enough collateral, try to get some via COMP
        // This scenario is rare and will happen during last withdraw
        if (_amount > cToken.balanceOfUnderlying(address(this))) {
            // Use all collateral for withdraw
            _collateralBefore = 0;
            _claimRewardsAndConvertTo(address(collateralToken));
            // Updated amount
            _amount = _amount - collateralToken.balanceOf(address(this));
        }
        _redeemUnderlying(_amount);
        uint256 _collateralAfter = collateralToken.balanceOf(address(this));
        return _collateralAfter - _collateralBefore;
    }

    /**
     * @notice This function will be called by flash loan
     * @dev In case of borrow, DyDx is preferred as fee is so low that it does not effect
     * our collateralRatio and liquidation risk.
     */
    function _flashLoanLogic(bytes memory _data, uint256 _repayAmount) internal override {
        (uint256 _amount, bool _deficit) = abi.decode(_data, (uint256, bool));
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        require(_collateralHere >= _amount, "FLASH_FAILED"); // to stop malicious calls

        //if in deficit we repay amount and then withdraw
        if (_deficit) {
            _repayBorrow(_amount);
            //if we are withdrawing we take more to cover fee
            _redeemUnderlying(_repayAmount);
        } else {
            _mint(_collateralHere);
            //borrow more to cover fee
            _borrowCollateral(_repayAmount);
        }
    }

    /**
     * @dev If swap slippage is defined then use oracle to get amountOut and calculate minAmountOut
     */
    function _safeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) private {
        uint256 _minAmountOut =
            swapSlippage != 10000
                ? _calcAmtOutAfterSlippage(
                    ORACLE.assetToAsset(_tokenIn, _amountIn, _tokenOut, TWAP_PERIOD),
                    swapSlippage
                )
                : 1;
        _safeSwap(_tokenIn, _tokenOut, _amountIn, _minAmountOut);
    }

    //////////////////// Compound wrapper functions //////////////////////////////
    /**
     * @dev Compound support ETH as collateral not WETH. So ETH strategy can override
     * below functions and handle wrap/unwrap of WETH.
     */
    function _mint(uint256 _amount) internal virtual {
        require(cToken.mint(_amount) == 0, "supply-to-compound-failed");
    }

    function _redeemUnderlying(uint256 _amount) internal virtual {
        require(cToken.redeemUnderlying(_amount) == 0, "withdraw-from-compound-failed");
    }

    function _borrowCollateral(uint256 _amount) internal virtual {
        require(cToken.borrow(_amount) == 0, "borrow-from-compound-failed");
    }

    function _repayBorrow(uint256 _amount) internal virtual {
        require(cToken.repayBorrow(_amount) == 0, "repay-to-compound-failed");
    }

    //////////////////////////////////////////////////////////////////////////////

    /* solhint-disable no-empty-blocks */

    // We overridden _generateReport which eliminates need of below function.
    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {}

    function _realizeProfit(uint256 _totalDebt) internal virtual override returns (uint256) {}

    function _realizeLoss(uint256 _totalDebt) internal view override returns (uint256 _loss) {}

    /* solhint-enable no-empty-blocks */
}
