// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./CompoundXYStrategy.sol";
import "./IVesperPool.sol";
import "./IPoolRewards.sol";

/// @title Deposit Collateral in Compound and earn interest by depositing borrowed token in a Vesper Pool.
contract VesperCompoundXYStrategy is CompoundXYStrategy {
    using SafeERC20 for IERC20;

    // Destination Grow Pool for borrowed Token
    IVesperPool public immutable vPool;
    // VSP token address
    address public immutable vsp;

    constructor(
        address _pool,
        address _swapManager,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        address _borrowCToken,
        address _vPool,
        address _vsp,
        string memory _name
    ) CompoundXYStrategy(_pool, _swapManager, _comptroller, _rewardToken, _receiptToken, _borrowCToken, _name) {
        require(_vsp != address(0), "vsp-address-is-zero");
        require(address(IVesperPool(_vPool).token()) == borrowToken, "invalid-grow-pool");
        vPool = IVesperPool(_vPool);
        vsp = _vsp;
    }

    /// @notice Gets amount of borrowed Y collateral in strategy + Y collateral amount deposited in vPool
    function borrowBalance() external view returns (uint256) {
        return _getBorrowBalance();
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return super.isReservedToken(_token) || _token == address(vPool);
    }

    /// @notice Calculate total value based reward accrued (COMP and VSP), supply and borrow position
    function totalValue() public view override returns (uint256 _totalValue) {
        _totalValue = super.totalValue();
        address _poolRewards = vPool.poolRewards();
        if (_poolRewards != address(0)) {
            (, uint256[] memory _claimableAmounts) = IPoolRewards(_poolRewards).claimable(address(this));
            uint256 _vspAmount = _claimableAmounts[0];
            if (_vspAmount > 0) {
                (, uint256 _vspAsCollateral, ) =
                    swapManager.bestOutputFixedInput(vsp, address(collateralToken), _vspAmount);
                // Update totalValue
                _totalValue += _vspAsCollateral;
            }
        }
    }

    /// @notice After borrowing Y, deposit to Vesper Pool
    function _afterBorrowY(uint256 _amount) internal override {
        vPool.deposit(_amount);
    }

    function _approveRouter(address _router, uint256 _amount) internal override {
        super._approveRouter(_router, _amount);
        IERC20(vsp).safeApprove(_router, _amount);
    }

    function _approveToken(uint256 _amount) internal override {
        super._approveToken(_amount);
        IERC20(borrowToken).safeApprove(address(vPool), _amount);
    }

    /// @notice Before repaying Y, withdraw it from Vesper Pool
    function _beforeRepayY(uint256 _amount) internal override {
        _withdrawFromPool(_amount);
    }

    function _claimRewardsAndConvertTo(address _toToken) internal override {
        super._claimRewardsAndConvertTo(_toToken);
        address _poolRewards = vPool.poolRewards();
        if (_poolRewards != address(0)) {
            IPoolRewards(_poolRewards).claimReward(address(this));
            uint256 _vspAmount = IERC20(vsp).balanceOf(address(this));
            if (_vspAmount > 0) {
                _safeSwap(vsp, _toToken, _vspAmount, 1);
            }
        }
    }

    /// @notice Borrowed Y balance deposited in Vesper Pool
    function _getBorrowBalance() internal view override returns (uint256) {
        return
            IERC20(borrowToken).balanceOf(address(this)) +
            ((vPool.pricePerShare() * vPool.balanceOf(address(this))) / 1e18);
    }

    function _rebalanceBorrow(uint256 _excessBorrow) internal override {
        if (_excessBorrow > 0) {
            uint256 _borrowedHereBefore = IERC20(borrowToken).balanceOf(address(this));
            _withdrawFromPool(_excessBorrow);
            uint256 _borrowedHere = IERC20(borrowToken).balanceOf(address(this)) - _borrowedHereBefore;
            if (_borrowedHere > 0) {
                _safeSwap(borrowToken, address(collateralToken), _borrowedHere, 1);
            }
        }
    }

    /// @notice Withdraw _shares proportional to collateral _amount from vPool
    function _withdrawFromPool(uint256 _amount) internal {
        uint256 _pricePerShare = vPool.pricePerShare();
        uint256 _shares = (_amount * 1e18) / _pricePerShare;
        _shares = _amount > ((_shares * _pricePerShare) / 1e18) ? _shares + 1 : _shares;

        uint256 _maxShares = vPool.balanceOf(address(this));
        vPool.withdraw(_shares > _maxShares ? _maxShares : _shares);
    }
}
