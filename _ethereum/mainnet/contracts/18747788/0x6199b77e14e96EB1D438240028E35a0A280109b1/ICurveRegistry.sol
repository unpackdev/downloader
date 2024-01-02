// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ICurveRegistry {
    // solhint-disable func-name-mixedcase
    function get_n_coins(address _pool) external view returns (uint256[2] memory);

    function get_rates(address _pool) external view returns (uint256[8] memory);

    function get_coin_indices(address _pool, address _from, address _to) external view returns (int128, int128, bool);
}
