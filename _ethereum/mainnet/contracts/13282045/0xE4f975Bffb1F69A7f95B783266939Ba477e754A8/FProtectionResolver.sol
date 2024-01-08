// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./ILendingPool.sol";
import "./CAave.sol";
import "./DSMath.sol";

// Formula to get slippage from HealthFactor
/// @dev _currentHealthFactor current health factor
/// @dev _totalNormalizedCollateralInEth current total amount of Col x liquidation threshold
/// @dev _expectedTotalBorrowInEth expected total amount of Debt in Eth after protection
function getSlippageInETH(
    uint256 _currentHealthFactor,
    uint256 _totalNormalizedCollateralInEth,
    uint256 _expectedTotalBorrowInEth
) pure returns (uint256) {
    return
        _wdiv(
            _totalNormalizedCollateralInEth -
                _wmul(_currentHealthFactor, _expectedTotalBorrowInEth),
            _currentHealthFactor
        );
}

function _isPositionUnsafe(address _user, uint256 _minimumHF)
    view
    returns (bool)
{
    (, , , , , uint256 currenthealthFactor) = ILendingPool(LENDINGPOOL)
        .getUserAccountData(_user);
    return currenthealthFactor < _minimumHF;
}

function _isAllowed(
    address _aToken,
    address _user,
    address _spender,
    uint256 _allowedAmt
) view returns (bool) {
    return
        IERC20(_aToken).balanceOf(_user) >= _allowedAmt &&
        IERC20(_aToken).allowance(_user, _spender) >= _allowedAmt;
}
