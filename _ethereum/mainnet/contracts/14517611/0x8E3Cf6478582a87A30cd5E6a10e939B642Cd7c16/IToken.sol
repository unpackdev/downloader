//Made with Student Coin Terminal
//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IBurnable.sol";
import "./ISaleSupply.sol";
import "./IVestingSupply.sol";

interface IToken is IBurnable, ISaleSupply, IVestingSupply {}
