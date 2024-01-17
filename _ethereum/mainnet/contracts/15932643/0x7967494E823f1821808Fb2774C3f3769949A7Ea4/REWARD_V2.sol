// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract REWARD_V2 {
    address private addrA = address(0x0e8c6ed32a5587C78434fA3410821FcA444C1B74);
    address private addrB = address(0xb9a4203428a86ee97a2Cc62D8fc78b4e6b544a86);
    address private addrC = address(0x2c809B96eED8dB4b0b9D3C6D158E639de23ca4A8);
    address private addrD = address(0xD33E55E35b741Cc4146A0c0b4A53668A14EbF986);
    address private addrE = address(0x07b8C927E44A2929e0Bb494F630ac1469757b8eB);
    using SafeERC20 for IERC20;
    constructor() {}

    function withdrawReward() external {
        IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        uint256 balanceUSDT = usdt.balanceOf(address(this));
        require(balanceUSDT > 0, "Nothing to pay!");

        IERC20 tokenOMDAO = IERC20(address(0xA4282798c2199a1C58843088297265acD748168c));
        uint256 totalOMDAOBanalce = tokenOMDAO.totalSupply();

        uint256 amountA = balanceUSDT * 5 / 100;
        uint256 amountB = balanceUSDT * 2 / 10;
        uint256 amountC = balanceUSDT * 5 / 100;
        uint256 amountD = balanceUSDT * 2 / 10;
        uint256 amountE = balanceUSDT * 5 / 10;

        if (totalOMDAOBanalce >= 10000000 * 10**6) {

            amountB = balanceUSDT * 25 / 100;
            amountC = balanceUSDT * 75 / 1000;
            amountD = balanceUSDT * 125 / 1000;

        }
        usdt.safeTransfer(addrA, amountA);
        usdt.safeTransfer(addrB, amountB);
        usdt.safeTransfer(addrC, amountC);
        usdt.safeTransfer(addrD, amountD);
        usdt.safeTransfer(addrE, amountE);
    }
}