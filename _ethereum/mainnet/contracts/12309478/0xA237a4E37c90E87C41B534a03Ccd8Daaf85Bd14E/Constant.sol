/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

library Constant {
    // the standard 10**18 Amount Multiplier
    uint256 public constant MULTIPLIERX10E18 = 10**18;

    // the valid ETH and DAI addresses (Rinkeby, TBD: Mainnet)
    address public constant BCNATIVETOKENADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // product status enumerations
    uint256 public constant PRODUCTSTATUS_ENABLED = 1;
    uint256 public constant PRODUCTSTATUS_DISABLED = 2;

    // the cover status enumerations
    uint256 public constant COVERSTATUS_ACTIVE = 0;
    uint256 public constant COVERSTATUS_EXPIRED = 1;
    uint256 public constant COVERSTATUS_CLAIMINPROGRESS = 2;
    uint256 public constant COVERSTATUS_CLAIMDONE = 3;

    // the claim status enumerations
    uint256 public constant CLAIMSTATUS_SUBMITTED = 0;
    uint256 public constant CLAIMSTATUS_INVESTIGATING = 1;
    uint256 public constant CLAIMSTATUS_PREPAREFORVOTING = 2;
    uint256 public constant CLAIMSTATUS_VOTING = 3;
    uint256 public constant CLAIMSTATUS_VOTINGCOMPLETED = 4;
    uint256 public constant CLAIMSTATUS_ABDISCRETION = 5;
    uint256 public constant CLAIMSTATUS_COMPLAINING = 6;
    uint256 public constant CLAIMSTATUS_COMPLAININGCOMPLETED = 7;
    uint256 public constant CLAIMSTATUS_ACCEPTED = 8;
    uint256 public constant CLAIMSTATUS_REJECTED = 9;
    uint256 public constant CLAIMSTATUS_PAYOUTREADY = 10;
    uint256 public constant CLAIMSTATUS_PAID = 11;

    // the voting outcome status enumerations
    uint256 public constant OUTCOMESTATUS_NONE = 0;
    uint256 public constant OUTCOMESTATUS_ACCEPTED = 1;
    uint256 public constant OUTCOMESTATUS_REJECTED = 2;

    // 1inch
    address public constant ONEINCH_OPEN_SPLIT_ADDRESS = address(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E);

    // uniswap
    address public constant UNISWAPV2_ROUTER_ADDRESS = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
}
