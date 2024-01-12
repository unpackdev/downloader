// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IOperatorMint {
    function operatorMint(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
}
