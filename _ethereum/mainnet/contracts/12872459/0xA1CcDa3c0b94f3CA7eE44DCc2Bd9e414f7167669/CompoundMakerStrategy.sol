// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./MakerStrategy.sol";
import "./ICompound.sol";

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Compound to earn interest.
abstract contract CompoundMakerStrategy is MakerStrategy {
    using SafeERC20 for IERC20;

    address internal constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    CToken internal immutable cToken;
    Comptroller internal constant COMPTROLLER = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _receiptToken,
        bytes32 _collateralType
    ) MakerStrategy(_pool, _cm, _swapManager, _receiptToken, _collateralType) {
        require(_receiptToken != address(0), "cToken-address-is-zero");
        cToken = CToken(_receiptToken);
    }

    /**
     * @notice Report total value of this strategy
     * @dev Make sure to return value in collateral token.
     * @dev Total value = DAI earned + COMP earned + Collateral locked in Maker
     */
    function totalValue() external view virtual override returns (uint256 _totalValue) {
        uint256 _daiBalance = _getDaiBalance();
        uint256 _debt = cm.getVaultDebt(address(this));
        if (_daiBalance > _debt) {
            uint256 _daiEarned = _daiBalance - _debt;
            (, _totalValue) = swapManager.bestPathFixedInput(DAI, address(collateralToken), _daiEarned, 0);
        }

        uint256 _compAccrued = COMPTROLLER.compAccrued(address(this));
        if (_compAccrued != 0) {
            (, uint256 _compAsCollateral) =
                swapManager.bestPathFixedInput(COMP, address(collateralToken), _compAccrued, 0);
            _totalValue += _compAsCollateral;
        }
        _totalValue += convertFrom18(cm.getVaultBalance(address(this)));
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view override returns (bool) {
        return _token == receiptToken || _token == COMP;
    }

    /**
     * @notice Returns true if pool is underwater.
     * @notice Underwater - If debt is greater than earning of pool.
     * @notice Earning - Sum of DAI balance and DAI from accrued reward, if any, in lending pool.
     * @dev There can be a scenario when someone calls claimComp() periodically which will
     * leave compAccrued = 0 and pool might be underwater. Call rebalance() to liquidate COMP.
     */
    function isUnderwater() public view override returns (bool) {
        uint256 _compAccrued = COMPTROLLER.compAccrued(address(this));
        uint256 _daiEarned;
        if (_compAccrued != 0) {
            (, _daiEarned) = swapManager.bestPathFixedInput(COMP, DAI, _compAccrued, 0);
        }
        return cm.getVaultDebt(address(this)) > (_getDaiBalance() + _daiEarned);
    }

    function _approveToken(uint256 _amount) internal override {
        super._approveToken(_amount);
        IERC20(DAI).safeApprove(address(receiptToken), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(COMP).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /// @notice Claim rewardToken from lender and convert it into DAI
    function _claimRewardsAndConvertTo(address _toToken) internal override {
        address[] memory _markets = new address[](1);
        _markets[0] = address(cToken);
        COMPTROLLER.claimComp(address(this), _markets);

        uint256 _compAmount = IERC20(COMP).balanceOf(address(this));
        if (_compAmount > 0) {
            _safeSwap(COMP, _toToken, _compAmount, 1);
        }
    }

    function _depositDaiToLender(uint256 _amount) internal override {
        if (_amount != 0) {
            require(cToken.mint(_amount) == 0, "deposit-in-compound-failed");
        }
    }

    function _getDaiBalance() internal view override returns (uint256) {
        return (cToken.balanceOf(address(this)) * cToken.exchangeRateStored()) / 1e18;
    }

    /**
     * @dev Rebalance DAI in lender. If lender has more DAI than DAI debt in Maker
     * then withdraw excess DAI from lender. If lender is short on DAI, underwater,
     * then deposit DAI to lender.
     * @dev There may be a scenario where we do not have enough DAI to deposit to
     * lender, in that case pool will be underwater even after rebalanceDai.
     */
    function _rebalanceDaiInLender() internal override {
        uint256 _daiDebtInMaker = cm.getVaultDebt(address(this));
        uint256 _daiInLender = _getDaiBalance();
        if (_daiInLender > _daiDebtInMaker) {
            _withdrawDaiFromLender(_daiInLender - _daiDebtInMaker);
        } else if (_daiInLender < _daiDebtInMaker) {
            // We have more DAI debt in Maker than DAI in lender
            uint256 _daiNeeded = _daiDebtInMaker - _daiInLender;
            uint256 _daiBalanceHere = IERC20(DAI).balanceOf(address(this));
            if (_daiBalanceHere > _daiNeeded) {
                _depositDaiToLender(_daiNeeded);
            } else {
                _depositDaiToLender(_daiBalanceHere);
            }
        }
    }

    function _withdrawDaiFromLender(uint256 _amount) internal override {
        require(cToken.redeemUnderlying(_amount) == 0, "withdraw-from-compound-failed");
    }
}
