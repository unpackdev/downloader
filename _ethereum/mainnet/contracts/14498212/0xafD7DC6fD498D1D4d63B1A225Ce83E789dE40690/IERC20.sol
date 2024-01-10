//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ERC20 used for the 'withdrawERC20' just-in-case function, there is no actual erc20 involved here.
interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}
