// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// solhint-disable func-name-mixedcase

interface ICurveSwapInt128 {
    function get_dy(int128 _from, int128 _to, uint256 _amount) external view returns (uint256);
    function get_dy_underlying(int128 _from, int128 _to, uint256 _amount) external view returns (uint256);
}

interface ICurveSwapUint256 {
    function get_dy(uint256 _from, uint256 _to, uint256 _amount) external view returns (uint256);
    function get_dy_underlying(uint256 _from, uint256 _to, uint256 _amount) external view returns (uint256);
}
