// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface ITTT {
    function boardState(uint256 boardIndex) external view returns (uint256);

    function getOpponent(uint256 boardIndex) external view returns (uint256);

    function victories(uint256 boardIndex) external view returns (uint256);
}
