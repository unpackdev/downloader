// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IERC20.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./CAave.sol";
import "./FGelatoDebtBridge.sol";
import "./FMaker.sol";

function _isAaveLiquid(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return
        IERC20(_debtToken).balanceOf(
            ILendingPool(
                ILendingPoolAddressesProvider(LENDING_POOL_ADDRESSES_PROVIDER)
                    .getLendingPool()
            )
                .getReserveData(_debtToken)
                .aTokenAddress
        ) > _debtAmt;
}
