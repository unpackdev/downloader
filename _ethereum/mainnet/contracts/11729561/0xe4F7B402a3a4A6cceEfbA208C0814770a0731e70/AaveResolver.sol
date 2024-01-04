// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ILendingPool.sol";
import "./SAave.sol";
import "./IERC20.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./CAave.sol";
import "./FAave.sol";
import "./FAaveHasLiquidity.sol";
import "./FAavePositionWillBeSafe.sol";

contract AaveResolver {
    function getATokenUnderlyingBalance(address _underlying)
        public
        view
        returns (uint256)
    {
        return
            IERC20(_underlying).balanceOf(
                ILendingPool(
                    ILendingPoolAddressesProvider(
                        LENDING_POOL_ADDRESSES_PROVIDER
                    )
                        .getLendingPool()
                )
                    .getReserveData(_underlying)
                    .aTokenAddress
            );
    }

    function getPosition(address _dsa)
        public
        view
        returns (AaveUserData memory)
    {
        return _getUserData(_dsa);
    }

    function hasLiquidity(address _debtToken, uint256 _debtAmt)
        public
        view
        returns (bool)
    {
        return _isAaveLiquid(_debtToken, _debtAmt);
    }

    function aavePositionWouldBeSafe(
        address _dsa,
        uint256 _colAmt,
        address _colToken,
        uint256 _debtAmt,
        address _oracleAggregator
    ) public view returns (bool) {
        return
            _aavePositionWillBeSafe(
                _dsa,
                _colAmt,
                _colToken,
                _debtAmt,
                _oracleAggregator
            );
    }
}
