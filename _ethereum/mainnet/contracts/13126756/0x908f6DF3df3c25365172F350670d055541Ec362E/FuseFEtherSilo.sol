// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./FullMath.sol";
import "./WETH.sol";
import "./ISilo.sol";

interface IFEther {
    function accrueInterest() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function isCEther() external view returns (bool);
}

contract FuseFEtherSilo is ISilo {
    using SafeERC20 for IERC20;

    IFEther public immutable fEther;

    constructor(IFEther _fEther) {
        require(_fEther.isCEther(), "Aloe: not fEther");
        fEther = _fEther;
    }

    function poke() external override {
        fEther.accrueInterest();
    }

    function deposit(uint256 amount) external override {
        if (amount == 0) return;
        WETH.withdraw(amount);
        fEther.mint{value: amount}();
    }

    function withdraw(uint256 amount) external override {
        if (amount == 0) return;
        uint256 fAmount = 1 + FullMath.mulDiv(amount, 1e18, fEther.exchangeRateStored());

        require(fEther.redeem(fAmount) == 0, "Fuse: redeem ETH failed");
        WETH.deposit{value: amount}();
    }

    function balanceOf(address account) external view override returns (uint256 balance) {
        return FullMath.mulDiv(fEther.balanceOf(account), fEther.exchangeRateStored(), 1e18);
    }

    function shouldAllowEmergencySweepOf(address token) external view override returns (bool shouldAllow) {
        shouldAllow = token != address(fEther);
    }
}
