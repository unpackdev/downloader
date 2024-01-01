// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICurveMetaRegistry {
    function get_lp_token(address pool) external view returns (address);

    function get_underlying_coins(
        address pool
    ) external view returns (address[8] calldata);

    function is_meta(address pool) external view returns (bool);

    function get_coins(
        address pool
    ) external view returns (address[8] calldata);

    function get_balances(
        address pool
    ) external view returns (uint256[8] calldata);
}
