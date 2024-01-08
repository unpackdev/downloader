// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./MakerStrategy.sol";
import "./AaveCore.sol";

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Aave to earn interest.
abstract contract AaveMakerStrategy is MakerStrategy, AaveCore {
    using SafeERC20 for IERC20;

    //solhint-disable no-empty-blocks
    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _receiptToken,
        bytes32 _collateralType
    ) MakerStrategy(_pool, _cm, _swapManager, _receiptToken, _collateralType) AaveCore(_receiptToken) {}

    /// @notice Initiate cooldown to unstake aave.
    function startCooldown() external onlyKeeper returns (bool) {
        return _startCooldown();
    }

    /// @notice Unstake Aave from stakedAave contract
    function unstakeAave() external onlyKeeper {
        _unstakeAave();
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _isReservedToken(_token);
    }

    function _approveToken(uint256 _amount) internal override {
        super._approveToken(_amount);
        IERC20(DAI).safeApprove(address(aaveLendingPool), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(AAVE).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /**
     * @notice Transfer StakeAave to newStrategy
     * @param _newStrategy Address of newStrategy
     */
    function _beforeMigration(address _newStrategy) internal override {
        super._beforeMigration(_newStrategy);
        IERC20(stkAAVE).safeTransfer(_newStrategy, stkAAVE.balanceOf(address(this)));
    }

    /// @notice Claim Aave rewards and convert to _toToken.
    function _claimRewardsAndConvertTo(address _toToken) internal override {
        uint256 _aaveAmount = _claimAave();
        if (_aaveAmount > 0) {
            _safeSwap(AAVE, _toToken, _aaveAmount, 1);
        }
    }

    function _depositDaiToLender(uint256 _amount) internal override {
        aaveLendingPool.deposit(DAI, _amount, address(this), 0);
    }

    function _rebalanceDaiInLender() internal override {
        uint256 _daiDebt = cm.getVaultDebt(address(this));
        uint256 _daiBalance = _getDaiBalance();
        if (_daiBalance > _daiDebt) {
            _withdrawDaiFromLender(_daiBalance - _daiDebt);
        }
    }

    function _withdrawDaiFromLender(uint256 _amount) internal override {
        _safeWithdraw(DAI, address(this), _amount);
    }

    function _getDaiBalance() internal view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }
}
