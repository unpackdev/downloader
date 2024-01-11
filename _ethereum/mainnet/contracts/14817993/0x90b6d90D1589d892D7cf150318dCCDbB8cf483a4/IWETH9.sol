// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad_) external;

    function approve(address guy_, uint256 wad_) external returns (bool);

    function transfer(address dst_, uint256 wad_) external returns (bool);

    function transferFrom(
        address src_,
        address dst_,
        uint256 wad_
    ) external returns (bool);

    function balanceOf(address guy_) external view returns (uint256);

    function allowance(address owner_, address spender_)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);
}
