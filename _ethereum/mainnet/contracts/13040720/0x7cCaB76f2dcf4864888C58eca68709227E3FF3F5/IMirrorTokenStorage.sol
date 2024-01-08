// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IGovernable.sol";

interface IMirrorTokenStorage {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}
