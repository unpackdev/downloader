// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IEntry {
    struct Entry {
        // Percentage of the total contract balance
        // that goes to the exact strategy
        uint8 weight;
        // Preferred token for which most exchanges will be made
        address entryToken;
        // Address of the pool on curve
        address curvePool;
        // Token with which we enter the pool
        address poolToken;
        // How many tokens pool contains
        uint8 poolSize;
        // PoolToken index in pool
        uint8 tokenIndexInCurve;
        // Address of the pool on convex
        // zero address if not exist
        address convexPoolAddress;
        // special pool id on convex
        uint256 convexPoold;
    }
}
