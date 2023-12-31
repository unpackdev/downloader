// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";

import "./CoreStorage.sol";
import "./Utils.sol";

struct ERC721Locker {
    /// @notice Locked tokens count of the collection.
    ///     Note: Collection Address => Number of locked tokens
    mapping(address => uint256) count;
    /// @notice Map of the locked tokens.
    ///     Note: Collection Address => Token ID => isLocked
    mapping(address => mapping(uint256 => bool)) tokens;
}

/// @title Cyan Wallet ERC721 Module - A Cyan wallet's ERC721 token handling module.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract ERC721Module is CoreStorage, IModule {
    // keccak256("wallet.ERC721Module.lockedERC721")
    bytes32 private constant LOCKER_SLOT = 0x25888debd3e1e584ccaebe1162c7763ec457a94078c5d0d9a1d32a926ff9973c;

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
            require(!checkIsLocked(collection, tokenId), "Cannot perform this action on locked token.");
        }
        if (funcHash == ERC721_APPROVE) {
            uint256 tokenId = Utils.getUint256At(data, 0x24);
            require(!checkIsLocked(collection, tokenId), "Cannot perform this action on locked token.");
        }
        if (funcHash == ERC721_SET_APPROVAL_FOR_ALL) {
            require(_getLocker().count[collection] == 0, "Cannot perform this action on locked token.");
        }

        return Utils._execute(collection, value, data);
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
        ERC721Locker storage locker = _getLocker();
        require(locker.tokens[collection][tokenId] != isLocked, "Token already in given state.");

        locker.tokens[collection][tokenId] = isLocked;
        if (isLocked) {
            ++locker.count[collection];
        } else {
            --locker.count[collection];
        }
        emit SetLockedERC721Token(collection, tokenId, isLocked);
    }

    /// @notice Allows operators to get the defaulted token.
    ///     Note: Can only transfer if token is locked.
    /// @param collection Collection address.
    /// @param tokenId Token ID.
    /// @param to Receiver address.
    function transferDefaultedERC721(
        address collection,
        uint256 tokenId,
        address to
    ) external returns (bytes memory) {
        require(checkIsLocked(collection, tokenId), "Cannot perform this action on non-locked token.");
        setLockedERC721Token(collection, tokenId, false);

        bytes memory data = abi.encodeWithSelector(ERC721_SAFE_TRANSFER_FROM, address(this), to, tokenId);
        return Utils._execute(collection, 0, data);
    }

    /// @notice Checks whether the token is locked or not.
    /// @param collection Collection address.
    /// @param tokenId Token ID.
    /// @return isLocked Whether the token is locked or not.
    function checkIsLocked(address collection, uint256 tokenId) public view virtual returns (bool) {
        return _getLocker().tokens[collection][tokenId];
    }

    /// @dev Returns the map of the locked tokens.
    /// @return result ERC721Locker struct of the locked tokens.
    ///     Note: Collection Address => Token ID => isLocked
    function _getLocker() internal pure returns (ERC721Locker storage result) {
        assembly {
            result.slot := LOCKER_SLOT
        }
    }
}
