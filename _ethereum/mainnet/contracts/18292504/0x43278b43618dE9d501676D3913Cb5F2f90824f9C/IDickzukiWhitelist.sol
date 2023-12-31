// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDickzukiWhitelist {
    function isWhitelisted(address address_) external view returns (bool);

    function setWhitelisted(address[] memory address_, bool toggle) external;
}
