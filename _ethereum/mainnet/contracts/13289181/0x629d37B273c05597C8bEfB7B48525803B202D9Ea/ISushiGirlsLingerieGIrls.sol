// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ISushiGirls {
    function sushiGirls(uint256 id)
        external
        view
        returns (
            uint256 originPower,
            uint256 supportedLPTokenAmount,
            uint256 sushiRewardDebt
        );
}

interface ILingerieGirls {
    function lingerieGirls(uint256 id)
        external
        view
        returns (
            uint256 originPower,
            uint256 supportedLPTokenAmount,
            uint256 sushiRewardDebt
        );
}
