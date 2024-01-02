// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";

import "./Utils.sol";
import "./CoreStorage.sol";
import "./Lockers.sol" as Lockers;

/// @title Cyan Wallet Fallback Handler - A Cyan wallet's fallback handler.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract FallbackHandler is CoreStorage, IERC721Receiver, IERC1155Receiver {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)"));
    bytes4 internal constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    // bytes4(keccak256("supportsInterface(bytes4)"))
    bytes4 private constant ERC165_INTERFACE = 0x01ffc9a7;

    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    event EthTransferred(address indexed receiver, uint256 value);

    /// @notice Allows the wallet to receive an ERC721 tokens.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC721_RECEIVED;
    }

    /// @notice Allows the wallet to receive an ERC1155 token.
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155_RECEIVED;
    }

    /// @notice Allows the wallet to receive an ERC1155 tokens.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155_BATCH_RECEIVED;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /// @notice Return whether the signature provided is valid for the provided data.
    /// @param data Data signed on the behalf of the wallet.
    /// @param signature Signature byte array associated with the data.
    /// @return magicValue Returns a magic value (0x1626ba7e) if the given signature is correct.
    function isValidSignature(bytes32 data, bytes calldata signature) external view returns (bytes4 magicValue) {
        require(signature.length == 65, "Invalid signature length.");
        address signer = Utils.recoverSigner(data, signature);
        require(signer == _owner, "Invalid signer.");
        return ERC1271_MAGIC_VALUE;
    }

    function isLockedERC721(address collection, uint256 tokenId) external view returns (bool) {
        return Lockers.isLockedERC721(collection, tokenId);
    }

    function isLockedByCyanPlanERC721(address collection, uint256 tokenId) external view returns (bool) {
        return Lockers.isLockedByCyanPlanERC721(collection, tokenId);
    }

    function isLockedByApePlan(address collection, uint256 tokenId) external view returns (bool) {
        return Lockers.isLockedByApePlan(collection, tokenId);
    }

    function getLockedERC1155Amount(address collection, uint256 tokenId) external view returns (uint256) {
        return Lockers.getLockedERC1155Amount(collection, tokenId);
    }

    function getApeLockState(address collection, uint256 tokenId) external view returns (uint8) {
        return Lockers.getApeLockState(collection, tokenId);
    }
}
