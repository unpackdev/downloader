/*
twitter: https://twitter.com/oldmoneytoken
telegram: https://t.me/oldmoneyportal
website: https://www.oldmoney.wtf/
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
