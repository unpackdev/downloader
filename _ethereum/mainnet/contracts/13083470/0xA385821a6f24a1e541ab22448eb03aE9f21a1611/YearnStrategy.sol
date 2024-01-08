// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
import "./Strategy.sol";
import "./IYToken.sol";

/// @title This strategy will deposit collateral token in a Yearn vault and earn interest.
abstract contract YearnStrategy is Strategy {
    using SafeERC20 for IERC20;

    IYToken internal immutable yToken;

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) Strategy(_pool, _swapManager, _receiptToken) {
        require(_receiptToken != address(0), "yToken-address-is-zero");
        yToken = IYToken(_receiptToken);
    }

    /**
     * @notice Calculate total value using underlying yToken
     * @dev Report total value in collateral token
     */
    function totalValue() public view override returns (uint256 _totalValue) {
        _totalValue = _getCollateralBalance();
    }

    function isReservedToken(address _token) public view override returns (bool) {
        return _token == address(yToken);
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(yToken), _amount);
    }

    /**
     * @notice Before migration hook. no rewards, so empty implementation
     * @param _newStrategy Address of new strategy.
     */
    //solhint-disable-next-line no-empty-blocks
    function _beforeMigration(address _newStrategy) internal override {}

    /// @notice Withdraw collateral to payback excess debt
    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {
        if (_excessDebt != 0) {
            _payback = _safeWithdraw(_excessDebt);
        }
    }

    /**
     * @notice Calculate earning and withdraw it from Yearn.
     * @param _totalDebt Total collateral debt of this strategy
     * @return profit in collateral token
     */
    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256) {
        uint256 _collateralBalance = _getCollateralBalance();
        if (_collateralBalance > _totalDebt) {
            _withdrawHere(_collateralBalance - _totalDebt);
        }
        return collateralToken.balanceOf(address(this));
    }

    /**
     * @notice Calculate realized loss.
     * @return _loss Realized loss in collateral token
     */
    function _realizeLoss(uint256 _totalDebt) internal view override returns (uint256 _loss) {
        uint256 _collateralBalance = _getCollateralBalance();

        if (_collateralBalance < _totalDebt) {
            _loss = _totalDebt - _collateralBalance;
        }
    }

    /// @notice Deposit collateral in Yearn vault
    function _reinvest() internal virtual override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            yToken.deposit(_collateralBalance);
        }
    }

    /// @dev Withdraw collateral and transfer it to pool
    function _withdraw(uint256 _amount) internal override {
        _safeWithdraw(_amount);
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    /**
     * @notice Safe withdraw will make sure to check asking amount against available amount.
     * @param _amount Amount of collateral to withdraw.
     * @return Actual collateral withdrawn
     */
    function _safeWithdraw(uint256 _amount) internal returns (uint256) {
        uint256 _collateralBalance = _getCollateralBalance();
        // Get minimum of _amount and _collateralBalance
        return _withdrawHere(_amount < _collateralBalance ? _amount : _collateralBalance);
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 _amount) internal returns (uint256) {
        // Returns the exact collateral amount withdrawed from yVault
        return yToken.withdraw(_convertToShares(_amount));
    }

    /// @dev Gets collateral balance into yVault
    function _getCollateralBalance() internal view returns (uint256) {
        return (yToken.balanceOf(address(this)) * yToken.pricePerShare()) / (10**yToken.decimals());
    }

    /// @dev Converts a collateral amount in its relative shares for yVault
    function _convertToShares(uint256 _collateralAmount) internal view returns (uint256) {
        return (_collateralAmount * (10**yToken.decimals())) / yToken.pricePerShare();
    }
}
