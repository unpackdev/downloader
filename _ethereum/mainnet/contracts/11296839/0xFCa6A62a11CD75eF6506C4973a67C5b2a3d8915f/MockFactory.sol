//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./IERC20.sol";
import "./IPairFactory.sol";
import "./MockPair.sol";

contract MockFactory is IPairFactory {

    mapping(address => mapping(address => address)) public pairs;

    function createPair(address a, address b) external override returns (address) {
        MockPair pair = new MockPair(a, b);
        pairs[a][b] = address(pair);
        return address(pair);
    }

    function getPair(address a, address b) external view override returns (address) {
        return pairs[a][b];
    }
}