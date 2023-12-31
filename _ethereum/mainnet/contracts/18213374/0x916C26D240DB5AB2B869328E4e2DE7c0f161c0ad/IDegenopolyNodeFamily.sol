// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./IERC721Upgradeable.sol";

interface IDegenopolyNodeFamily is IERC721Upgradeable {
    function color() external view returns (string memory);

    function rewardBoost() external view returns (uint256);

    function mint(address to) external;
}
