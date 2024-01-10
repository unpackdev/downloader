//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function coins(uint256 _coinIndex) external view returns (address);

    function remove_liquidity_one_coin(
        uint256 _burnAmount,
        int128 _i,
        uint256 _minAmount,
        address _receiver
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burnAmount, int128 _i)
        external
        view
        returns (uint256);
}

interface ICurveMeta is ICurvePool {
    function get_dy_underlying(
        int128 _i,
        int128 _j,
        uint256 _iAmount
    ) external view returns (uint256);

    function exchange_underlying(
        int128 _i,
        int128 _j,
        uint256 _iAmount,
        uint256 _minAmount
    ) external view returns (uint256);
}

interface ILPCurve {
    function minter() external view returns (address);
}

interface ICurveGauge {
    function lp_token() external view returns (address);
}
