// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

interface ITwapReader {
    function getPairParameters(address pair)
        external
        view
        returns (
            bool exists,
            uint112 reserve0,
            uint112 reserve1,
            uint256 price,
            uint256 mintFee,
            uint256 burnFee,
            uint256 swapFee
        );
}
