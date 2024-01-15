// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IRWaste is IERC20 {
    function burn(address, uint256) external;
    function claimLaboratoryExperimentRewards(address, uint256) external;
}