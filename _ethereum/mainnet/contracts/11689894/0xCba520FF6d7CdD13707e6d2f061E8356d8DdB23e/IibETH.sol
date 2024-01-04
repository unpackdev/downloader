// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface IibETH {

    function totalETH()
        external
        view
        returns (uint256);

}
