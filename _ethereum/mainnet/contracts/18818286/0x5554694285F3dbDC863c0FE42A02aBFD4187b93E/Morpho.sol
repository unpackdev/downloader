// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Strategy.sol";
import "./IMorpho.sol";

/// @title This strategy will deposit base asset i.e. USDC in Morpho and earn yield.
/// @dev MORPHO token is non transferable.
/// https://docs.morpho.org/governance/morpho-token/non-transferability-and-future-distribution
/// Due to this we can only claim MORPHO but can not swap. Once transfer is allowed
/// we will be able to sweep those out from contract.
abstract contract Morpho is Strategy {
    using SafeERC20 for IERC20;

    error AddressIsNull();

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.1.0";

    ISupplyVault public immutable supplyVault;

    constructor(
        address pool_,
        address swapper_,
        address receiptToken_,
        string memory name_
    ) Strategy(pool_, swapper_, receiptToken_) {
        if (receiptToken_ == address(0)) revert AddressIsNull();
        supplyVault = ISupplyVault(receiptToken_);
        NAME = name_;
    }

    /// @dev Morpho token is not reserved as we will sweep it out for swap.
    function isReservedToken(address token_) public view virtual override returns (bool) {
        return token_ == address(supplyVault);
    }

    function tvl() external view override returns (uint256) {
        return _getCollateralInProtocol() + collateralToken.balanceOf(address(this));
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        collateralToken.safeApprove(address(supplyVault), amount_);
    }

    //solhint-disable-next-line no-empty-blocks
    function _beforeMigration(address newStrategy_) internal virtual override {}

    /**
     * @dev Deposit collateral in Morpho.
     */
    function _deposit(uint256 _amount) internal virtual {
        if (_amount > 0) {
            supplyVault.deposit(_amount, address(this));
        }
    }

    /// Get total collateral deposited in protocol
    function _getCollateralInProtocol() internal view returns (uint256) {
        return supplyVault.convertToAssets(supplyVault.balanceOf(address(this)));
    }

    /**
     * @dev Generate report for pools accounting and also send profit and any payback to pool.
     */
    function _rebalance() internal virtual override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _collateralHere + _getCollateralInProtocol();
        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }

        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_profitAndExcessDebt > _collateralHere) {
            _withdrawHere(_profitAndExcessDebt - _collateralHere);
            _collateralHere = collateralToken.balanceOf(address(this));
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        // After reportEarning strategy may get more collateral from pool. Deposit those in Morpho.
        _deposit(collateralToken.balanceOf(address(this)));
    }

    /// @dev Withdraw collateral here.
    function _withdrawHere(uint256 _amount) internal override {
        // Get minimum of _amount and _available collateral
        uint256 _withdrawAmount = Math.min(_amount, supplyVault.maxWithdraw(address(this)));
        supplyVault.withdraw(_withdrawAmount, address(this), address(this));
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/

    /**
     * @notice onlyKeeper:: Claim MORPHO token.
     */
    function claimRewards(uint256 claimable_, bytes32[] calldata proof_) external onlyKeeper {
        supplyVault.recipient().claim(address(this), claimable_, proof_);
    }
}
