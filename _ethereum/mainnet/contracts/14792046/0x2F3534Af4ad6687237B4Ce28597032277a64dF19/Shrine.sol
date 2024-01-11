// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ShrineInterface {
    function roundsSurvived(uint256 _id) external view returns (uint256);

    function secret() external view returns (uint256);
}
