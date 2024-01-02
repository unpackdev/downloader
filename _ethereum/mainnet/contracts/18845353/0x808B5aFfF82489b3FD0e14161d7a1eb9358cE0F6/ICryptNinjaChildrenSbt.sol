// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICryptNinjaChildrenSbt {
    function adminMint(uint256 _phaseId, address[] calldata _addresses, uint256[] memory _userMintAmounts) external;
}
