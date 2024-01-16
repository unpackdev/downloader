// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title ITokenOwnershipFacet
/// @author Kfish n Chips
/// @dev Required interface of an ERC721 compliant contract.
/// @custom:security-contact security@kfishnchips.com
interface ITokenOwnershipFacet  {
    error QueryBalanceOfZeroAddress();
    error QueryNonExistentToken();
    error QueryBurnedToken();

    function ownerOf(uint256 _tokenId) external view returns (address);
}
