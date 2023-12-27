// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC721.sol";

struct Config {
    bool Initialised;
    bool NumericOnly;
    bool CanOverwriteSubdomains;
    string[] DomainArray;
}
