// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./LibGovTierStorage.sol";

interface IGovTier {
    function getSingleTierData(
        bytes32 _tierLevelKey
    ) external view returns (LibGovTierStorage.TierData memory);

    function isAlreadyTierLevel(
        bytes32 _tierLevel
    ) external view returns (bool);

    function getGovTierLevelKeys() external view returns (bytes32[] memory);

    function getWalletTier(
        address _userAddress
    ) external view returns (bytes32 _tierLevel);
}
