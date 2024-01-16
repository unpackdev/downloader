// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Dao {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function price() external view returns (uint256);

    function limit() external view returns (uint256);

    function presale() external view returns (uint256);
}
