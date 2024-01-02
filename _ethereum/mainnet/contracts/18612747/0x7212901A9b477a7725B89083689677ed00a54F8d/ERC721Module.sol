// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";

import "./IModule.sol";
import "../core/Lockers.sol" as Lockers;
import "./Utils.sol";

/// @title Cyan Wallet ERC721 Module - A Cyan wallet's ERC721 token handling module.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract ERC721Module is IModule {
    bytes4 private constant ERC721_APPROVE = IERC721.approve.selector;
    bytes4 private constant ERC721_SET_APPROVAL_FOR_ALL = IERC721.setApprovalForAll.selector;
    bytes4 private constant ERC721_TRANSFER_FROM = IERC721.transferFrom.selector;
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_BYTES =
        bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));

    event SetLockedERC721Token(address collection, uint256 tokenId, bool isLocked);

    /// @inheritdoc IModule
    function handleTransaction(
        address collection,
        uint256 value,
        bytes calldata data
    ) public payable virtual override returns (bytes memory) {
        bytes4 funcHash = Utils.parseFunctionSelector(data);
        if (
            funcHash == ERC721_TRANSFER_FROM ||
            funcHash == ERC721_SAFE_TRANSFER_FROM ||
            funcHash == ERC721_SAFE_TRANSFER_FROM_BYTES
        ) {
            uint256 tokenId = Utils.getUint256At(data, 0x44);
            require(!getIsLocked(collection, tokenId), "Cannot perform this action on locked token.");
        }
        if (funcHash == ERC721_APPROVE) {
            uint256 tokenId = Utils.getUint256At(data, 0x24);
            require(!getIsLocked(collection, tokenId), "Cannot perform this action on locked token.");
        }
        require(funcHash != ERC721_SET_APPROVAL_FOR_ALL, "Cannot perform this action.");

        return Utils._execute(collection, value, data);
    }

    function getIsLocked(address collection, uint256 tokenId) internal view virtual returns (bool) {
        return Lockers.isLockedByCyanPlanERC721(collection, tokenId);
    }

    /// @notice Allows operators to lock/unlock the token.
    /// @param collection Collection address.
    /// @param tokenId Token id.
    /// @param isLocked Boolean represents lock/unlock.
    function setLockedERC721Token(
        address collection,
        uint256 tokenId,
        bool isLocked
    ) public {
        Lockers.CyanPlanLockerERC721 storage locker = Lockers.getCyanPlanLockerERC721();
        require(locker.tokens[collection][tokenId] != isLocked, "Token already in given state.");

        locker.tokens[collection][tokenId] = isLocked;
        if (isLocked) {
            ++locker.count[collection];
        } else {
            --locker.count[collection];
        }
        emit SetLockedERC721Token(collection, tokenId, isLocked);
    }

    /// @notice Allows operators to transfer out non locked ERC721 tokens.
    ///     Note: Can only transfer if token is not locked.
    /// @param collection Collection address.
    /// @param tokenId Token ID.
    /// @param to Receiver address.
    function transferNonLockedERC721(
        address collection,
        uint256 tokenId,
        address to
    ) external returns (bytes memory) {
        require(!Lockers.isLockedERC721(collection, tokenId), "Cannot perform this action on locked token.");

        bytes memory data = abi.encodeWithSelector(ERC721_SAFE_TRANSFER_FROM, address(this), to, tokenId);
        return Utils._execute(collection, 0, data);
    }
}
