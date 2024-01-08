//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISvgValidator {
    function isValid(string memory check) external view returns (bool);
}
