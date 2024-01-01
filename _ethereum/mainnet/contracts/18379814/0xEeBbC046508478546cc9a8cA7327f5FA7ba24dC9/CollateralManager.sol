// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface CollateralManager {
    struct Collateral {
        CollateralType _collateralType;
        uint256 _amount;
        uint256 _tokenId;
        address _collateralAddress;
    }

    enum CollateralType {
        ERC20,
        ERC721,
        ERC1155
    }

    function getCollateralInfo(uint256 _bidId) external view returns (Collateral[] memory infos_);
}