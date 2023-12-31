// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

// Reference: https://github.com/ethereum-optimism/optimism-tutorial/blob/main/cross-dom-comm/contracts/Greeter.sol

import "./ICrossDomainMessenger.sol";

library CrossDomainOrigin {
    /**
     * Returns the CrossDomainMessenger for the given destinationOpChainId_
     *
     */
    function crossDomainMessenger(uint256 crossDomainChainId_) internal view returns (address cdmAddr) {
        // Get the cross domain messenger's address each time.
        // This is less resource intensive than writing to storage.

        // Mainnet -> Optimism
        if (block.chainid == 1 && crossDomainChainId_ == 10) cdmAddr = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

        // Mainnet -> Base
        if (block.chainid == 1 && crossDomainChainId_ == 8453) cdmAddr = 0x866E82a600A1414e583f7F13623F1aC5d58b0Afa;

        // Mainnet -> Zora
        if (block.chainid == 1 && crossDomainChainId_ == 7777777) cdmAddr = 0xdC40a14d9abd6F410226f1E6de71aE03441ca506;

        // Goerli -> Goerli Optimism
        if (block.chainid == 5 && crossDomainChainId_ == 420) cdmAddr = 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294;

        // Goerli -> Goerli Base
        if (block.chainid == 5 && crossDomainChainId_ == 84531) cdmAddr = 0x8e5693140eA606bcEB98761d9beB1BC87383706D;

        // Goerli -> Goerli Zora
        if (block.chainid == 5 && crossDomainChainId_ == 999) cdmAddr = 0xD87342e16352D33170557A7dA1e5fB966a60FafC;

        // Op Stack
        if (
            // Optimism -> Mainnet
            (block.chainid == 10 && crossDomainChainId_ == 1)
            // Base -> Mainnet
            || (block.chainid == 8453 && crossDomainChainId_ == 1)
            // Zora -> Mainnet
            || (block.chainid == 7777777 && crossDomainChainId_ == 1)
            // Goerli Optimism -> Goerli
            || (block.chainid == 420 && crossDomainChainId_ == 5)
            // Goerli Base -> Goerli
            || (block.chainid == 84531 && crossDomainChainId_ == 5)
            // Goerli Zora -> Goerli
            || (block.chainid == 999 && crossDomainChainId_ == 5)
        ) cdmAddr = 0x4200000000000000000000000000000000000007;
    }

    function getCrossDomainMessageSender(uint256 crossDomainChainId_) internal view returns (address) {
        // Get the cross domain messenger's address each time.
        // This is less resource intensive than writing to storage.
        address cdmAddr = crossDomainMessenger(crossDomainChainId_);

        // If this isn't a cross domain message
        if (msg.sender != cdmAddr) {
            revert("Not crosschain call");
        }

        // If it is a cross domain message, find out where it is from
        return ICrossDomainMessenger(cdmAddr).xDomainMessageSender();
    }
}
