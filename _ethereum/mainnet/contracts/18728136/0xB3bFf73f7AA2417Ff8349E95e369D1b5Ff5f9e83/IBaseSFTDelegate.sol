// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBaseSFTDelegate  {
    function delegateToConcreteView(bytes calldata data) external view returns (bytes memory);
}
