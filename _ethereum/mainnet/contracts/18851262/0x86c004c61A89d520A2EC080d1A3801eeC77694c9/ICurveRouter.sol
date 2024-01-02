// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/* solhint-disable func-name-mixedcase */
interface ICurveRouter {
    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external returns (uint256);

    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external returns (uint256);

    function get_best_rate(address _from, address _to, uint256 _amount) external view returns (address, uint256);

    function get_input_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);

    function get_exchange_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);
}
