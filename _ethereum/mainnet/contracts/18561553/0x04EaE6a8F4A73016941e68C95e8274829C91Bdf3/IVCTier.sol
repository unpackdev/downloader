// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibVCTierStorage.sol";

interface IVCTier {
    function getVCTier(
        address _vcTierNFT
    ) external view returns (LibVCTierStorage.VCNFTTier memory);

    function getUserVCNFTTier(
        address _wallet
    ) external view returns (LibVCTierStorage.VCNFTTier memory);
}
