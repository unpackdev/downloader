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

import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./IQBridgeHandler.sol";
import "./IQBridgeDelegator.sol";
import "./IQore.sol";
import "./SafeToken.sol";
import "./QBridgeToken.sol";


contract QBridgeDelegator is IQBridgeDelegator, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    uint public constant OPTION_QUBIT_BNB_NONE = 100;
    uint public constant OPTION_QUBIT_BNB_0100 = 110;
    uint public constant OPTION_QUBIT_BNB_0050 = 105;
    uint public constant OPTION_BUNNY_XLP_0150 = 215;

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) public handlerWhitelist; // handler address => is whitelisted
    mapping(address => address) public marketAddress; // xToken address => market address
    IQore public qore;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyBridgeHandler() {
        require(handlerWhitelist[msg.sender], "QBridgeDelegator: caller is not the whitelisted handler contract");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "QBridgeDelegator: invalid qore address");
        require(address(qore) == address(0), "QBridgeDelegator: qore already set");
        qore = IQore(_qore);
    }

    function setHandlerWhitelist(address _handler, bool option) external onlyOwner {
        handlerWhitelist[_handler] = option;
    }

    function setMarket(address xToken, address market) external onlyOwner {
        require(xToken != address(0), "QBridgeDelegator: invalid xToken address");
        require(market != address(0), "QBridgeDelegator: invalid market address");
        marketAddress[xToken] = market;
    }

    function approveTokenForMarket(address token, address market) external onlyOwner {
        require(token != address(0), "QBridgeDelegator: invalid xToken address");
        require(market != address(0), "QBridgeDelegator: invalid market address");
        QBridgeToken(token).approve(market, uint(- 1));
    }

    /* ========== MUTATIVE  ========== */

    function delegate(address xToken, address recipientAddress, uint option, uint amount) external override onlyBridgeHandler {
        if (option == OPTION_QUBIT_BNB_NONE) {
            qore.supplyAndBorrowBNB(recipientAddress, marketAddress[xToken], amount, 0);
        }
        else if (option == OPTION_QUBIT_BNB_0050) {
            qore.supplyAndBorrowBNB(recipientAddress, marketAddress[xToken], amount, 5e16);
        }
    }
}
