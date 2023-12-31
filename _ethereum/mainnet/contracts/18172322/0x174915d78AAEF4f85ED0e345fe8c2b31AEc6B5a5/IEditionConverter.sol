// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IEditionConverter {
    error CallerNotNftCreatorVerifier();

    error EditionNftContractNotRegistered(
        uint256 originalNftChainId_, address originalNftContract_, uint256 originalNftTokenId_
    );

    function convertToEditions(
        uint256 originalNftChainId_,
        address originalNftContract_,
        uint256 originalNftTokenId_,
        address creator_,
        string calldata collectionImageUri_,
        string calldata name_,
        string calldata symbol_
    ) external;
}
