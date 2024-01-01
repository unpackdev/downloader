//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface INFT {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply,
        uint256 expirationTime
    ) external;
}
