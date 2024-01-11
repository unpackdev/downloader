//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ITrueFreezeGovernor {
    function getPositions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        );

    function getTokenSymbol() external view returns (string memory);
}
