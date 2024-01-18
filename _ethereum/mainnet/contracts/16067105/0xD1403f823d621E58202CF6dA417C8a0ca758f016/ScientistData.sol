// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Representation of scientist with it fields
 */
library ScientistData {
    /**
     *  Represents the basic parameters that describes scientist
     */
    struct Scientist {
        uint256 price;
        bool onSale;
        Point point;
    }

    struct Point {
        uint32 physics;
        uint32 chemistry;
        uint32 biology;
        uint32 sociology;
        uint32 mathematics;
    }
}
