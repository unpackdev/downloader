// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Morpho.sol";
import "./IMorpho.sol";

/// @title This strategy will deposit base asset i.e. USDC in Morpho and earn yield.

contract MorphoAave is Morpho {
    constructor(
        address pool_,
        address swapper_,
        address receiptToken_,
        string memory name_
    ) Morpho(pool_, swapper_, receiptToken_, name_) {}
}
