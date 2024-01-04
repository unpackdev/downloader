/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IEtherToken.sol";

import "./ComptrollerLib.sol";

/**
 * @title EnzymePoolController
 * @author David Lucid <david@rari.capital> (https://github.com/davidlucid)
 * @dev This library handles deposits to and withdrawals from Enzyme's Rari ETH (technically WETH) pool.
 */
library EnzymePoolController {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev The WETH contract address.
     */
    address constant private WETH_CONTRACT = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**
     * @dev The WETH contract object.
     */
    IEtherToken constant private _weth = IEtherToken(WETH_CONTRACT);

    /**
     * @dev Alpha Homora ibETH token contract address.
     */
    address constant private IBETH_CONTRACT = 0x67B66C99D3Eb37Fa76Aa3Ed1ff33E8e39F0b9c7A;

    /**
     * @dev Returns the fund's balance of ETH (technically WETH) in the Enzyme pool.
     */
    function getBalance(address comptroller) external returns (uint256) {
        ComptrollerLib _comptroller = ComptrollerLib(comptroller);
        (uint256 price, bool valid) = _comptroller.calcGrossShareValue(true);
        require(valid, "Enzyme gross share value not valid.");
        return IERC20(_comptroller.getVaultProxy()).balanceOf(address(this)).mul(price).div(1e18);
    }

    /**
     * @dev Approves WETH to the Enzyme pool Comptroller without spending gas on every deposit.
     * @param comptroller The Enzyme pool Comptroller contract address.
     * @param amount Amount of the WETH to approve to the Enzyme pool Comptroller.
     */
    function approve(address comptroller, uint256 amount) external {
        uint256 allowance = _weth.allowance(address(this), comptroller);
        if (allowance == amount) return;
        if (amount > 0 && allowance > 0) _weth.approve(comptroller, 0);
        _weth.approve(comptroller, amount);
    }

    /**
     * @dev Deposits funds to the Enzyme pool. Assumes that you have already approved >= the amount to the Enzyme Comptroller contract.
     * @param comptroller The Enzyme pool Comptroller contract address.
     * @param amount The amount of ETH to be deposited.
     */
    function deposit(address comptroller, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        _weth.deposit.value(amount)();
        
        address[] memory buyers = new address[](1);
        buyers[0] = address(this);
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        
        uint256[] memory minShares = new uint256[](1);
        minShares[0] = 0;
        
        ComptrollerLib(comptroller).buyShares(buyers, amounts, minShares);
    }

    /**
     * @dev Withdraws funds from the Enzyme pool.
     * @param comptroller The Enzyme pool Comptroller contract address.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdraw(address comptroller, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");

        ComptrollerLib _comptroller = ComptrollerLib(comptroller);
        (uint256 price, bool valid) = _comptroller.calcGrossShareValue(true);
        require(valid, "Enzyme gross share value not valid.");
        uint256 shares = amount.mul(1e18).div(price);
        if (shares.mul(price).div(1e18) < amount) shares++; // Round up if necessary (i.e., if the division above left a remainder)
        
        address[] memory additionalAssets = new address[](0);
        address[] memory assetsToSkip = new address[](0);

        _comptroller.redeemSharesDetailed(shares, additionalAssets, assetsToSkip);
        
        _weth.withdraw(_weth.balanceOf(address(this)));
    }

    /**
     * @dev Withdraws all funds from the Enzyme pool.
     * @param comptroller The Enzyme pool Comptroller contract address.
     */
    function withdrawAll(address comptroller) external {
        ComptrollerLib(comptroller).redeemShares();
        _weth.withdraw(_weth.balanceOf(address(this)));
    }
}