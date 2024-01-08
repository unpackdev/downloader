// SPDX-License-Identifier:MIT
pragma solidity 0.7.6;

interface INymLib {
    function toBase58(bytes memory source) external pure returns (string memory);
    function validateName(string memory str) external pure returns (bool);
    function toLower(string memory str) external pure returns (string memory);
}
