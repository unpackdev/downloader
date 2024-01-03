// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./FGelatoDebtBridge.sol";

contract FGelatoDebtBridgeMock {
    function wCalcCollateralToWithdraw(
        uint256 _wMinColRatioMaker,
        uint256 _wMinColRatioB,
        uint256 _wColPrice,
        uint256 _wPricedCol,
        uint256 _wDaiDebtOnMaker
    ) public pure returns (uint256) {
        return
            _wCalcCollateralToWithdraw(
                _wMinColRatioMaker,
                _wMinColRatioB,
                _wColPrice,
                _wPricedCol,
                _wDaiDebtOnMaker
            );
    }

    function wCalcDebtToRepay(
        uint256 _wMinColRatioMaker,
        uint256 _wMinColRatioB,
        uint256 _wPricedCol,
        uint256 _wDaiDebtOnMaker
    ) public pure returns (uint256) {
        return
            _wCalcDebtToRepay(
                _wMinColRatioMaker,
                _wMinColRatioB,
                _wPricedCol,
                _wDaiDebtOnMaker
            );
    }

    function getFlashLoanRoute(address _tokenA, uint256 _wTokenADebtToMove)
        public
        view
        returns (uint256)
    {
        return _getFlashLoanRoute(_tokenA, _wTokenADebtToMove);
    }

    function getGasCostMakerToMaker(bool _newVault, uint256 _route)
        public
        pure
        returns (uint256)
    {
        return _getGasCostMakerToMaker(_newVault, _route);
    }

    function getGasCostMakerToCompound(uint256 _route)
        public
        pure
        returns (uint256)
    {
        return _getGasCostMakerToCompound(_route);
    }

    function getRealisedDebt(uint256 _debtToMove)
        public
        pure
        returns (uint256)
    {
        return _getRealisedDebt(_debtToMove);
    }
}
