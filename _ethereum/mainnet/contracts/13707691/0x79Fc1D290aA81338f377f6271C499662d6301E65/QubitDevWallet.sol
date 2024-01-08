// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "./Math.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";
import "./WhitelistUpgradeable.sol";
import "./SafeToken.sol";
import "./IQubitPool.sol";
import "./IQore.sol";

contract QubitDevWallet is WhitelistUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    IQubitPool public constant QubitPool = IQubitPool(0x33F93897e914a7482A262Ef10A94319840EB8D05);
    IQore public constant Qore = IQore(0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48);
    address internal constant qQBT = 0xcD2CD343CFbe284220677C78A08B1648bFa39865;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        IBEP20(QBT).approve(address(QubitPool), uint(- 1));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint _amount) public {
        QBT.safeTransferFrom(msg.sender, address(this), _amount);

        QubitPool.deposit(_amount);
    }

    function harvest() public onlyOwner {
        uint _before = QBT.balanceOf(address(this));
        QubitPool.getReward();
        uint amountQBT = QBT.balanceOf(address(this)).sub(_before);

        QubitPool.deposit(amountQBT);
    }

    function withdrawBQBT(uint _amount) public onlyOwner {
        QubitPool.withdraw(_amount);
        address(QubitPool).safeTransfer(msg.sender, _amount);
    }

    function approveQBTMarket() public onlyOwner {
        IBEP20(QBT).approve(qQBT, uint(- 1));
    }

    function supply(uint _amount) public {
        QBT.safeTransferFrom(msg.sender, address(this), _amount);

        Qore.supply(qQBT, _amount);
    }

    function redeemToken(uint _qAmount) public onlyOwner {
        uint uAmountToRedeem = Qore.redeemToken(qQBT, _qAmount);
        QBT.safeTransfer(msg.sender, uAmountToRedeem);
    }
}
