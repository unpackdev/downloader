//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IAskoStaking {
    function stakeValue(address stakerAddress)
        external
        view
        returns (uint256 amountStaked);
}
