// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./RariCore.sol";
import "./CompoundStrategy.sol";
import "./IComptroller.sol";
import "./IFusePoolDirectory.sol";

/// @title This strategy will deposit collateral token in a Rari Fuse Pool and earn interest.
contract RariFuseStrategy is CompoundStrategy {
    using SafeERC20 for IERC20;
    using RariCore for IFusePoolDirectory;

    uint256 public fusePoolId;
    IFusePoolDirectory public immutable fusePoolDirectory;
    address public rewardDistributor;
    event FusePoolChanged(uint256 indexed newFusePoolId, address indexed oldCToken, address indexed newCToken);

    constructor(
        address _pool,
        address _swapManager,
        uint256 _fusePoolId,
        IFusePoolDirectory _fusePoolDirectory,
        string memory _name
    )
        CompoundStrategy(
            _pool,
            _swapManager,
            _fusePoolDirectory.getComptroller(_fusePoolId),
            address(0), // rewardToken
            _fusePoolDirectory.getCTokenByUnderlying(
                _fusePoolId,
                address(IVesperPool(_pool).token()) == WETH ? address(0x0) : address(IVesperPool(_pool).token())
            ),
            _name
        )
    {
        fusePoolId = _fusePoolId;
        fusePoolDirectory = _fusePoolDirectory;
        // Find and set the rewardToken from the fuse pool data
        (rewardDistributor, rewardToken) = _fusePoolDirectory.getRewardToken(_fusePoolId);
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
        address _newCToken = fusePoolDirectory.getCTokenByUnderlying(_newPoolId, address(collateralToken));
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
        (rewardDistributor, rewardToken) = fusePoolDirectory.getRewardToken(fusePoolId);
    }

    /// @dev Manually claim rewards from rewardDistributor by keeper
    /// @notice Properly tests if reward claim works
    function claimRewards() external onlyKeeper {
        _claimRewards();
    }

    /// @notice Claim rewards from Fuse Pool' rewardDistributor
    function _claimRewards() internal virtual override {
        IRariRewardDistributor(rewardDistributor).claimRewards(address(this));
    }

    /// @notice Get rewards accrued in Fuse Pool' rewardDistributor
    function _getRewardAccrued() internal view virtual override returns (uint256 _rewardAccrued) {
        _rewardAccrued = IRariRewardDistributor(rewardDistributor).compAccrued(address(this));
    }

    // solhint-disable-next-line
    function _beforeMigration(address _newStrategy) internal override {}
}
