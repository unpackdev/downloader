// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./CrossDomainOrigin.sol";
import "./ICreatorVerifier.sol";
import "./ICreatorRegistry.sol";
import "./IEditionConverter.sol";
import "./ICrossDomainMessenger.sol";

contract CreatorVerifier is ICreatorVerifier {
    address private _creatorRegistry;
    address private _editionConverter;

    modifier onlyNftCreator(address nftContract_, uint256 tokenId_) {
        if (ICreatorRegistry(_creatorRegistry).getCreatorOf(nftContract_, tokenId_) != msg.sender) {
            revert CallerNotNftCreator(nftContract_, tokenId_);
        }

        _;
    }

    constructor(address creatorRegistry_, address editionConverter_) {
        _creatorRegistry = creatorRegistry_;
        _editionConverter = editionConverter_;
    }

    function claimProceedsAndCreateEditions(
        address originalNftContract_,
        uint256 originalNftTokenId_,
        uint256 editionNftChainId_,
        string calldata collectionImageUri_,
        string calldata name_,
        string calldata symbol_
    ) external override onlyNftCreator(originalNftContract_, originalNftTokenId_) {
        bytes memory message = abi.encodeCall(
            IEditionConverter.convertToEditions,
            (block.chainid, originalNftContract_, originalNftTokenId_, msg.sender, collectionImageUri_, name_, symbol_)
        );

        ICrossDomainMessenger(CrossDomainOrigin.crossDomainMessenger(editionNftChainId_)).sendMessage(
            _editionConverter,
            message,
            // The first 1.92M gas is free
            // https://community.optimism.io/docs/developers/bridge/messaging/#for-l1-%E2%87%92-l2-transactions
            1920000
        );

        emit ClaimProceedsAndCreateEditions(originalNftContract_, originalNftTokenId_);
    }

    function creatorRegistry() external view override returns (address) {
        return _creatorRegistry;
    }

    function editionConverter() external view override returns (address) {
        return _editionConverter;
    }
}
