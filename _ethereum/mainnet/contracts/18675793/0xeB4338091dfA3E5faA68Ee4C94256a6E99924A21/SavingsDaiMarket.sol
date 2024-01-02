// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
import "./IERC20.sol";

interface ISDai {
    function convertToAssets(uint256) external view returns (uint256);
    function convertToShares(uint256) external view returns (uint256);
    function deposit(uint256,address) external returns (uint256);
    function redeem(uint256,address,address) external returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

library SavingsDaiMarket {

    address constant sDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function exchangeRate() internal view returns (uint256) {
        return ISDai(sDAI).convertToAssets(1e18);
    }

    function balanceOf(address account) internal view returns (uint256) {
        return ISDai(sDAI).balanceOf(account);
    }

    function deposit(uint256 amount, address receiver) internal returns(uint256) {
        _approve(amount);
        return ISDai(sDAI).deposit(amount, receiver);
    }

    function redeem(uint256 amount, address receiver, address sender) internal returns(uint256) {
        return ISDai(sDAI).redeem(amount, receiver, sender);
    }

    function _approve(uint256 _amount) internal {
        if (IERC20(DAI).allowance(address(this), sDAI) < _amount){
            IERC20(DAI).approve(sDAI, ~uint256(0));
        }
    }
}