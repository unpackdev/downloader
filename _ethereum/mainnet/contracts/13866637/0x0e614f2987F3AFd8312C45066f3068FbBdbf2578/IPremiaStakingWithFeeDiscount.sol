// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IPremiaStaking.sol";
import "./IFeeDiscount.sol";

interface IPremiaStakingWithFeeDiscount is IPremiaStaking, IFeeDiscount {}
