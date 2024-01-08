// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IWhitelist {
    function isWhitelistedOtoken(address _otoken) external view returns (bool);
}
