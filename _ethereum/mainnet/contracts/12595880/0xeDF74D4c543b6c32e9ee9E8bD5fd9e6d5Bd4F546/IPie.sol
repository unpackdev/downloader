//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;

interface IPie {
    function calcTokensForAmount(uint256 _amount) external view returns(address[] memory tokens, uint256[] memory amounts);
}