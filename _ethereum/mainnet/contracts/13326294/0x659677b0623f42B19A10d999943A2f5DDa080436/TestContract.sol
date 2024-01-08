// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TestContract {

    error RevertFunction();

    function revertString() external {
        revert("RevertString");
    }

    function revertFunction() external {
        revert RevertFunction();
    }

}