// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FGelatoDebtBridge.sol";

contract FGelatoDebtBridgeMock {
    function getFlashLoanRoute(address _tokenA, uint256 _tokenADebtToMove)
        public
        view
        returns (uint256)
    {
        return _getFlashLoanRoute(_tokenA, _tokenADebtToMove);
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
