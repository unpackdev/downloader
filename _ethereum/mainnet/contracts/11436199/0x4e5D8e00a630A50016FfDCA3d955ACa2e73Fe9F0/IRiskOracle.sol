// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IRiskOracle {

    function latestAnswer()
        external
        view
        returns (int256);

}
