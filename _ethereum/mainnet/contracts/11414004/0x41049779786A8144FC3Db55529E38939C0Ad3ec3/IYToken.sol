// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface IYToken {

    function getPricePerFullShare()
        external
        view returns (uint);

}
