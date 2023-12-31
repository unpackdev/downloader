// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title implemenation
 * @notice implemenation layout for proxy design pattern
 */
abstract contract Implementation {    
    // implementation address needs to be the first declared variable.
    // it should be the first inheritance declaration in order to make proxy storage align.
    address private _implementation;
}