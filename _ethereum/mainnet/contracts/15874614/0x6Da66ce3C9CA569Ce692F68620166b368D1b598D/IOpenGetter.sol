// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERCNftInfos.sol";

interface IOpenGetter is IERCNftInfos {
    function getCollectionInfos(address collection, address account)
        external
        view
        returns (CollectionInfos memory collectionInfos);

    function getNftInfos(address collection, uint256 tokenID, address account)
        external
        view
        returns (NftInfos memory nftInfos);

    function getNftsInfos(address collection, address account, uint256 limit, uint256 offset)
        external
        view
        returns (NftInfos[] memory nftsInfos, uint256 count, uint256 total);

    function getNftsInfos(address collection, uint256[] memory tokenIDs, address account)
        external
        view
        returns (NftInfos[] memory nftsInfos);
}
