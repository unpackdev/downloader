// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "CollectionData.sol";
import "InterfaceType.sol";
import "Token.sol";
import "TokenData.sol";

interface ICxipIdentity {
    function addSignedWallet(
        address newWallet,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function addWallet(address newWallet) external;

    function connectWallet() external;

    function createERC721Token(
        address collection,
        uint256 id,
        TokenData calldata tokenData,
        Verification calldata verification
    ) external returns (uint256);

    function createERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData
    ) external returns (address);

    function createCustomERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData,
        bytes32 slot,
        bytes memory bytecode
    ) external returns (address);

    function init(address wallet, address secondaryWallet) external;

    function getAuthorizer(address wallet) external view returns (address);

    function getCollectionById(uint256 index) external view returns (address);

    function getCollectionType(address collection) external view returns (InterfaceType);

    function getWallets() external view returns (address[] memory);

    function isCollectionCertified(address collection) external view returns (bool);

    function isCollectionRegistered(address collection) external view returns (bool);

    function isNew() external view returns (bool);

    function isOwner() external view returns (bool);

    function isTokenCertified(address collection, uint256 tokenId) external view returns (bool);

    function isTokenRegistered(address collection, uint256 tokenId) external view returns (bool);

    function isWalletRegistered(address wallet) external view returns (bool);

    function listCollections(uint256 offset, uint256 length) external view returns (address[] memory);

    function nextNonce(address wallet) external view returns (uint256);

    function totalCollections() external view returns (uint256);

    function isCollectionOpen(address collection) external pure returns (bool);
}
