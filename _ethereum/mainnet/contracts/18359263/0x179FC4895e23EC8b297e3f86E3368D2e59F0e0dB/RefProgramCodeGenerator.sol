// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract RefProgramCodeGenerator {
    function generatedNonce(
        address user,
        uint256 roundID
    ) public pure returns (uint256) {
        uint256 id = uint256(keccak256(abi.encodePacked(user, roundID))) % 10;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(id, user)));
        return randomNumber;
    }
}
