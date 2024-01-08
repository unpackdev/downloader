// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IMigrator {
    // Perform LP token migration from legacy LPMining CompliFi to newer version.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to CompliFi LP tokens.
    // CompliFi must mint EXACTLY the same amount of ComplFi LP tokens or
    // else something bad will happen.
    function migrate(IERC20 token) external returns (IERC20);
}
