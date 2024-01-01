// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibGovNFTTierStorage.sol";

interface IGovNFTTier {
    function getUserNftTier(
        address _wallet
    )
        external
        view
        returns (LibGovNFTTierStorage.NFTTierData memory nftTierData);

    function getSingleSpTier(
        uint256 _spTierId
    ) external view returns (LibGovNFTTierStorage.SingleSPTierData memory);
}
