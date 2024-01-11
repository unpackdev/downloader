// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface StringDictionaryInterface {
    function setString(uint256 _key, string memory _string) external;
    function getString(uint256 _key) external view returns (string memory);
}
