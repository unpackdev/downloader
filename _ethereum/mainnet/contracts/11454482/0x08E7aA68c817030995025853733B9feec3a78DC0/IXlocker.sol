// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.6.6;
// Copyright (C) udev 2020
interface IXlocker {
    function launchERC20(string calldata name, string calldata symbol, uint wadToken, uint wadUeth) external returns (address token_, address pair_);
    function launchERC20TransferTax(string calldata name, string calldata symbol, uint wadToken, uint wadUeth, uint taxBips, address taxMan) external returns (address token_, address pair_);
}