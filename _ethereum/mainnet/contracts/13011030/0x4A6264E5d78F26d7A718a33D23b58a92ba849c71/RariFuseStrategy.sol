// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";
import "./IComptroller.sol";
import "./IFusePoolDirectory.sol";

/// @title This strategy will deposit collateral token in a Rari Fuse Pool and earn interest.
abstract contract RariFuseStrategy is CompoundStrategy {
    using SafeERC20 for IERC20;

    address private constant FUSE_POOL_DIRECTORY = 0x835482FE0532f169024d5E9410199369aAD5C77E;

    event FusePoolChanged(uint256 indexed newFusePoolId, address indexed oldCToken, address indexed newCToken);

    // solhint-disable no-empty-blocks
    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) CompoundStrategy(_pool, _swapManager, _receiptToken) {}

    // solhint-enable no-empty-blocks

    /**
     * @notice Calculate total value using underlying token
     * @dev Report total value in collateral token
     */
    function totalValue() external view override returns (uint256 _totalValue) {
        _totalValue = _convertToCollateral(cToken.balanceOf(address(this)));
    }

    /**
     * @notice Changes the underlying Fuse Pool to a new one
     * @dev Redeems cTokens from current fuse pool and mints cTokens of new Fuse Pool
     * @param _newPoolId Fuse Pool ID
     */
    function migrateFusePool(uint256 _newPoolId) external virtual onlyGovernor {
        address _newCToken = _cTokenByUnderlying(_newPoolId, address(collateralToken));
        require(address(cToken) != _newCToken, "same-fuse-pool");
        require(cToken.redeem(cToken.balanceOf(address(this))) == 0, "withdraw-from-fuse-pool-failed");
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        collateralToken.safeApprove(_newCToken, _collateralBalance);
        require(CToken(_newCToken).mint(_collateralBalance) == 0, "deposit-to-fuse-pool-failed");
        emit FusePoolChanged(_newPoolId, address(cToken), _newCToken);
        cToken = CToken(_newCToken);
        receiptToken = _newCToken;
    }

    function isReservedToken(address _token) public view override returns (bool) {
        return _token == address(cToken);
    }

    /**
     * @notice Gets the cToken to mint for a Fuse Pool
     * @param _poolId Fuse Pool ID
     * @param _collateralToken address of the collateralToken
     */
    function _cTokenByUnderlying(uint256 _poolId, address _collateralToken) internal view returns (address) {
        (, , address _comptroller, , ) = IFusePoolDirectory(FUSE_POOL_DIRECTORY).pools(_poolId);
        require(_comptroller != address(0), "rari-fuse-invalid-comptroller");
        address _cToken = IComptroller(_comptroller).cTokensByUnderlying(_collateralToken);
        require(_cToken != address(0), "rari-fuse-invalid-ctoken");
        return _cToken;
    }

    // solhint-disable-next-line
    function _beforeMigration(address _newStrategy) internal override {}

    /**
     * @notice Calculate earning and withdraw it from Rari Fuse
     * @dev If somehow we got some collateral token in strategy then we want to
     *  include those in profit. That's why we used 'return' outside 'if' condition.
     * @param _totalDebt Total collateral debt of this strategy
     * @return profit in collateral token
     */
    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256) {
        uint256 _collateralBalance = _convertToCollateral(cToken.balanceOf(address(this)));

        if (_collateralBalance > _totalDebt) {
            _withdrawHere(_collateralBalance - _totalDebt);
        }
        return collateralToken.balanceOf(address(this));
    }
}
