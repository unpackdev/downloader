// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurveSwapRouter {
    function exchange_multiple(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount,
        uint256 _expected
    ) external payable returns (uint256);

    function get_exchange_multiple_amount(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount
    ) external view returns (uint256);
}
