// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IWeth {
    // wrap ETH into WETH
    function deposit() external payable;

    // unwrap WETH back to ETH
    function withdraw(uint wad) external;

    function balanceOf(address account) external view returns (uint256);
}
