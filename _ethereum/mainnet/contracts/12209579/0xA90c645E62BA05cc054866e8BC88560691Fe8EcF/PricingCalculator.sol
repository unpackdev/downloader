// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract PricingCalculator {
     function priceCalculator(uint currentSupply) public view returns (uint256) {

        if (currentSupply >= 2375) {
            return 400000000000000000;        // 2376-2500: 0.4 ETH
        } else if (currentSupply >= 2250) {
            return 300000000000000000;         // 2251-2375:  0.3 ETH
        } else if (currentSupply >= 1875) {
            return 200000000000000000;         // 1876-2250:  0.2 ETH
        } else if (currentSupply >= 875) {
            return 100000000000000000;         // 876-1875:  0.1 ETH
        } else if (currentSupply >= 375) {
            return 50000000000000000;          // 376-875:  0.05 ETH 
        } else if (currentSupply >= 125) {
            return 40000000000000000;          // 126-375:   0.04 ETH 
        } else {
            return 30000000000000000;          // 0 - 125    0.03 ETH
        }

    }
}