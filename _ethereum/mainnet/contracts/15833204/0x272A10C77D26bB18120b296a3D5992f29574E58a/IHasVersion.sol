//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";

interface IHasVersion {
    function version() external view returns (string memory);
}
