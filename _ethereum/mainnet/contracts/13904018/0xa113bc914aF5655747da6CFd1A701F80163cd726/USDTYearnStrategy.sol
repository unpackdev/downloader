
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// Openzeppelin imports
import "./AccessControl.sol";
import "./ERC20.sol";

/// Yearn imports
import "./VaultInterface.sol";

/// Local imports
import "./YearnStrategy.sol";

/**
 * @title Implementation of the Yearn Strategy.
 *
 */
contract USDTYearnStrategy is YearnStrategy {

    /// Constructor
    constructor() {

    }

    /// Public override member functions

    function decimals() override virtual pure public returns(uint256) {
        return 6;
    }

    function vaultAddress() override pure public returns(address) {

        return 0x7Da96a3891Add058AdA2E826306D812C638D87a7;
    }

    function vaultTokenAddress() override pure public returns(address) {

        return 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    }
}
