// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

interface IAirdropSimple {
    struct AirdropConfig {
        address token;
        bytes32 merkleRoot;
        uint256 totalAirdroppedAmount;
    }

    function token() external view returns (address);

    function merkleRoot() external view returns (bytes32);

    function totalAirdroppedAmount() external view returns (uint256);

    function totalClaimed() external view returns (uint256);

    function claim(uint256 index, address account, uint256 amount, bytes32[] memory merkleProof) external;

    function isClaimed(uint256 index) external view returns (bool);
}
