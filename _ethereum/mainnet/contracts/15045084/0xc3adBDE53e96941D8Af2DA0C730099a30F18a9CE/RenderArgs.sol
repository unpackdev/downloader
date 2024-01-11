// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Graphics2D.sol";
import "./Parameters.sol";

struct RenderArgs {
    Graphics2D g;
    Parameters p;
    Matrix m;
}