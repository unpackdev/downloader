// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERCNftInfos.sol";

interface IOpenResolver is IERCNftInfos {
    function getCollectionsInfos(
        address[] memory collections,
        address account,
        bytes4[] memory interfaceIds
    ) external view returns (CollectionInfos[] memory collectionsInfos);
}
