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
import "./ReentrancyGuardUpgradeable.sol";

import "./WhitelistUpgradeable.sol";
import "./SafeToken.sol";
import "./IBEP20.sol";

contract QPromise is WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== STATE VARIABLES ========== */

    struct TokenData {
        address asset;
        uint amount;
    }

    mapping(address => TokenData) private _swaps;
    mapping(address => TokenData) private _repays;
    mapping(address => bool) public completes;

    /* ========== EVENTS ========== */

    event RepaymentClaimed(address indexed user, address asset, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setData(address[] memory accounts, TokenData[] memory receives, TokenData[] memory repays) external onlyOwner {
        require(accounts.length != 0 && accounts.length == receives.length && accounts.length == repays.length, "QRepayment: invalid data");
        for (uint i = 0; i < accounts.length; i++) {
            _swaps[accounts[i]] = receives[i];
            _repays[accounts[i]] = repays[i];
        }
    }

    function sweep(address asset) external onlyOwner {
        uint balance = IBEP20(asset).balanceOf(address(this));
        if (balance > 0) {
            asset.safeTransfer(msg.sender, balance);
        }
    }

    /* ========== VIEWS ========== */

    function infoOf(address account) external view returns (bool didClaim, address swapAsset, uint swapAmount, address repayAsset, uint repayAmount) {
        return (completes[account], _swaps[account].asset, _swaps[account].amount, _repays[account].asset, _repays[account].amount);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claim() external nonReentrant {
        require(!completes[msg.sender], "QRepayment: already claimed");
        completes[msg.sender] = true;

        address swapToken = _swaps[msg.sender].asset;
        uint swapAmount = _swaps[msg.sender].amount;
        delete _swaps[msg.sender];

        address repayToken = _repays[msg.sender].asset;
        uint repayAmount = _repays[msg.sender].amount;
        delete _repays[msg.sender];

        swapToken.safeTransferFrom(msg.sender, address(this), swapAmount);
        repayToken.safeTransfer(msg.sender, repayAmount);

        emit RepaymentClaimed(msg.sender, repayToken, repayAmount);
    }
}
