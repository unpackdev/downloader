// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundLeverageStrategy.sol";
import "./IToken.sol";

// solhint-disable no-empty-blocks
/// @title Deposit UNI in Compound and also borrow UNI based on leverage condition
contract CompoundLeverageStrategyUNI is CompoundLeverageStrategy {
    string public constant NAME = "Compound-Leverage-Strategy-UNI";
    string public constant VERSION = "3.0.12";

    // cUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550
    constructor(address _pool, address _swapManager)
        CompoundLeverageStrategy(_pool, _swapManager, 0x35A18000230DA775CAc24873d00Ff85BccdeD550)
    {}
}
