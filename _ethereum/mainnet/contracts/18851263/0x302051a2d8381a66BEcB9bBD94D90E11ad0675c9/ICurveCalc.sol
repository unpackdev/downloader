// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ICurveCalc {
    // solhint-disable func-name-mixedcase
    function get_dx(
        // solhint-disable-next-line var-name-mixedcase
        int128 n_coins,
        uint256[8] memory balances,
        uint256 amp,
        uint256 fee,
        uint256[8] memory rates,
        uint256[8] memory precisions,
        bool underlying,
        int128 i,
        int128 j,
        uint256 dy
    ) external pure returns (uint256);
}
