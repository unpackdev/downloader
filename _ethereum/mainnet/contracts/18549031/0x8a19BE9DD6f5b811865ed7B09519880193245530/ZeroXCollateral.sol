// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.23;

import "./IZeroXPair.sol";
import "./ZeroXERC20.sol";
import "./Math.sol";
import "./UQ112x112.sol";
import "./IERC20.sol";
import "./IZeroXFactory.sol";
import "./IZeroXCallee.sol";

abstract contract ZeroXCollateral is IZeroXPair, ZeroXERC20 {
    using UQ112x112 for uint224;

    uint256 public constant override MINIMUM_LIQUIDITY = 10 ** 3;
    //Store the collateral token address as WETH
    address public constant collateralToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //interest fixed rate at 1000% APR
    uint256 public constant interestRate = 1000;
    address public override factory;

    uint256 public collateralisedReserve; // Amount of collateral in the pool

    modifier onlyLoan() {
        require(msg.sender == IZeroXFactory(factory).loan(), "ZeroX: FORBIDDEN");
        _;
    }

    function isCollateralToken(address _token) external pure returns (bool) {
        if (_token == collateralToken) {
        return true;
        } else {
        return false;
        }
    }

    function increaseCollateralisedReserves(uint256 _collateralAmount) external onlyLoan returns (uint256) {
        return collateralisedReserve += _collateralAmount; //Only WETH is accepted as collateral
    }

    function decreaseCollateralisedReserves(uint256 _collateralAmount) external onlyLoan returns (uint256) {
        return collateralisedReserve -= _collateralAmount; //Only WETH is accepted as collateral
    }

}
