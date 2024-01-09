//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface ICollectionManager {
    event CollectionInitialized(
        address,
        address,
        string,
        string,
        string,
        uint256,
        uint256,
        uint256,
        uint256,
        address[],
        uint256[]
    );

    function initializeCollection(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        uint256 _startingAt,
        uint256 _maxSupply,
        uint256 _initialPrice,
        address[] memory _payees,
        uint256[] memory _shares
    ) external;

    function getCollections() external view returns (address[] memory);

    function getCollectionForArtist(address _artist) external view returns (address[] memory);

    function getArtistOfCollection(address _collectionAddress) external view returns (address);
}