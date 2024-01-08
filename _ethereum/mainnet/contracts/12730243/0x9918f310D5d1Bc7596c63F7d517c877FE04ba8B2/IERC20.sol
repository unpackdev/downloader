// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);

    function totalSupply() external view returns (uint256);
}
