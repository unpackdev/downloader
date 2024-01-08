//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;

interface IRecipe {
    function bake(
        address _inputToken,
        address _outputToken,
        uint256 _maxInput,
        bytes memory _data
    ) external returns (uint256 inputAmountUsed, uint256 outputAmount);
}