// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";
import "./IComptroller.sol";
import "./IFusePoolDirectory.sol";

/// @title This strategy will deposit collateral token in a Rari Fuse Pool and earn interest.
contract RariFuseStrategy is CompoundStrategy {
    using SafeERC20 for IERC20;
    string public constant NAME = "RariFuse-Strategy";
    string public constant VERSION = "3.0.13";
    uint256 public fusePoolId;
    address private constant FUSE_POOL_DIRECTORY = 0x835482FE0532f169024d5E9410199369aAD5C77E;
    event FusePoolChanged(uint256 indexed newFusePoolId, address indexed oldCToken, address indexed newCToken);

    constructor(
        address _pool,
        address _swapManager,
        uint256 _fusePoolId
    ) CompoundStrategy(_pool, _swapManager, _cTokenByUnderlying(_fusePoolId, address(IVesperPool(_pool).token()))) {
        fusePoolId = _fusePoolId;
    }

    // solhint-enable no-empty-blocks

    /**
     * @notice Calculate total value using underlying token
     * @dev Report total value in collateral token
     */
    function totalValue() public view override returns (uint256 _totalValue) {
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
        collateralToken.safeApprove(address(cToken), 0);
        // We usually do infinite approval via approveToken() any way
        collateralToken.safeApprove(_newCToken, MAX_UINT_VALUE);
        require(CToken(_newCToken).mint(collateralToken.balanceOf(address(this))) == 0, "deposit-to-fuse-pool-failed");
        emit FusePoolChanged(_newPoolId, address(cToken), _newCToken);
        cToken = CToken(_newCToken);
        receiptToken = _newCToken;
        fusePoolId = _newPoolId;
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
        if (_collateralToken == WETH) {
            // cETH is mapped with 0x0
            _collateralToken = address(0x0);
        }
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
    function _realizeProfit(uint256 _totalDebt) internal virtual override returns (uint256) {
        uint256 _collateralBalance = _convertToCollateral(cToken.balanceOf(address(this)));

        if (_collateralBalance > _totalDebt) {
            _withdrawHere(_collateralBalance - _totalDebt);
        }
        return collateralToken.balanceOf(address(this));
    }
}
