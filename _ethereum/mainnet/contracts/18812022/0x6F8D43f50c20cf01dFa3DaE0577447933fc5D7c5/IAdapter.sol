// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAdapter {
    function initialize(
        address _wrapper,
        address _vault,
        address _token0,
        address _token1,
        address _lpToken,
        address _admin
    ) external;

    function wrapper() external returns(address);

    function vault() external returns(address);

    function token0() external returns(address);

    function token1() external returns(address);

    function lpToken() external returns(address);

    function PROTOCOL() external returns(string memory);

    function VERSION() external returns(uint8);

    function PRECISION() external returns(uint256);

    function totalSupply() external view returns(uint256);

    function tokenPerShare() external view returns(uint256 _token0PerShare, uint256 _token1PerShare);

    function pool() external view returns(address);

    function deposit(
        uint256 _amount0,
        uint256 _amount1,
        address _user,
        bytes calldata _data
    ) external returns(uint256 _share);

    function withdraw(
        uint256 _share,
        address _user,
        bytes calldata _data
    ) external returns(uint256 _amount0, uint256 _amount1);
}