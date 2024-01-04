// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./IERC20.sol";

// https://etherscan.io/address/0xa9fE4601811213c340e850ea305481afF02f5b28

interface IyvwETHv2 is IERC20 {
    function deposit(uint256 _amount) external returns (uint256);

    function withdraw(uint256 _shares) external returns (uint256);

    function pricePerShare() external view returns (uint256);
}
