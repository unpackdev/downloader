// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IBaseUpgradeable.sol";

interface IBaseCollectionTypeUpgradeable {
    event SetTypeNFT(uint256 typeNFT, TypeInfo typeInfo);

    struct TypeInfo {
        bool executeOperation;
        address paymentToken;
        uint256 price;
        uint256 limit;
        IBaseUpgradeable.Operation operation;
    }

    error BaseCollectionTypeUpgradeable__ExceedLimit(uint256 typeNFT);
}
