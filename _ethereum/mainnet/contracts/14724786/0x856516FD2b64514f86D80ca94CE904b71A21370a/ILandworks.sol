// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./LibLandworks.sol";

interface ILandworks {
    // MarketplaceFacet
    function list(
        uint256 _metaverseId,
        address _metaverseRegistry,
        uint256 _metaverseAssetId,
        uint256 _minPeriod,
        uint256 _maxPeriod,
        uint256 _maxFutureTime,
        address _paymentToken,
        uint256 _pricePerSecond
    ) external returns (uint256);

    function changeConsumer(address _consumer, uint256 _tokenId) external;

    function delist(uint256 _assetId) external;

    function withdraw(uint256 _assetId) external;

    function rentAt(uint256 _assetId, uint256 _rentId) external view returns (LibLandworks.Rent memory);

    function assetAt(uint256 _assetId) external view returns (LibLandworks.Asset memory);

    // ERC721 functions
    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    // FeeFacet functions
    function assetRentFeesFor(uint256 _assetId, address _token) external view returns (uint256);

    function claimRentFee(uint256 _assetId) external;
}
