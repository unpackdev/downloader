//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "./IERC721EnumerableUpgradeable.sol";

interface ILunaWolves is IERC721EnumerableUpgradeable {
    function mint(address) external;
}