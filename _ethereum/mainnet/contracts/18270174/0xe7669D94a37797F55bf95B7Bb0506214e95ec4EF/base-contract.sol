// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

struct Point {
    uint256 x;
    uint256 y;
}
struct Body {
    Point[] p;
    uint256 balance;
}

contract BaseContract {
    uint z;

    constructor(uint t) {
        z = t;
    }
}
