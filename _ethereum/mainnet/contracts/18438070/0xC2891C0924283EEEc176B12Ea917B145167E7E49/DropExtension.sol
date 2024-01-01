// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: VERTICAL.art

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./IDropExtension.sol";

error InvalidDates();
error FailedToTransfer();
error DropInactive();
error InsufficientFunds();
error ExceedMaxSupply();

contract DropExtension is AdminControl, IDropExtension, ICreatorExtensionTokenURI {
    uint256 internal constant MAX_UINT_56 = 0xffffffffffffff;

    uint256 private _totalSupply;
    address public creator;
    uint256 public dropCounter;
    mapping(uint256 => Drop) public drops;
    mapping(uint256 => uint256) public tokenIdToDropId;

    constructor(address _creator) {
        require(_creator != address(0), "Invalid creator address");
        creator = _creator;
    }

    modifier creatorAdminRequired() {
        AdminControl creatorCoreContract = AdminControl(creator);
        require(
            creatorCoreContract.isAdmin(msg.sender),
            "Wallet is not an admin for creator contract"
        );
        _;
    }

    modifier validDrop(uint256 id, uint256 count) {
        Drop memory drop = drops[id];
        if (
            drop.startDate > uint64(block.timestamp) ||
            (drop.endDate > 0 && drop.endDate < uint64(block.timestamp))
        ) revert DropInactive();
        if (msg.value < drop.price * count) revert InsufficientFunds();
        if (drop.minted + count > drop.maxSupply) revert ExceedMaxSupply();
        _;
    }

    function withdraw(address payable receiver, uint256 amount) external adminRequired {
        (bool sent, ) = receiver.call{value: amount}("");
        if (!sent) revert FailedToTransfer();
    }

    function createDrop(DropParams calldata params) external override creatorAdminRequired {
        if (
            params.startDate < uint64(block.timestamp) ||
            (params.endDate > 0 && params.endDate < params.startDate)
        ) revert InvalidDates();

        dropCounter++;
        drops[dropCounter] = Drop({
            minted: 0,
            maxSupply: params.maxSupply,
            price: params.price,
            uri: params.uri,
            startDate: params.startDate,
            endDate: params.endDate
        });

        emit DropCreated(dropCounter, msg.sender);
    }

    function updateDrop(
        uint256 id,
        DropParams memory params
    ) external override creatorAdminRequired {
        Drop memory drop = drops[id];
        if (params.startDate < uint64(block.timestamp) || params.endDate < params.startDate)
            revert InvalidDates();
        if (params.maxSupply < drop.minted) {
            params.maxSupply = drop.minted;
        }
        if (params.maxSupply < drop.maxSupply) {
            params.maxSupply = drop.maxSupply;
        }

        // Overwrite the existing drop
        drops[id] = Drop({
            minted: drop.minted,
            maxSupply: params.maxSupply,
            uri: params.uri,
            price: params.price,
            startDate: params.startDate,
            endDate: params.endDate
        });
        emit DropUpdated(id);
    }

    function mint(uint256 id, uint16 count) external payable override validDrop(id, count) {
        Drop storage drop = drops[id];

        IERC721CreatorCore(creator).mintExtensionBatch(msg.sender, count);
        drop.minted += count;
        for (uint16 i; i < count; i += 1) {
            _totalSupply++;
            tokenIdToDropId[_totalSupply] = id;
        }

        if (msg.value > drop.price * count)
            payable(msg.sender).transfer(msg.value - drop.price * count);

        emit DropMinted(id, msg.sender, count);
    }

    function tokenURI(address, uint256 tokenId) external view override returns (string memory) {
        return drops[tokenIdToDropId[tokenId]].uri;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AdminControl, IERC165) returns (bool) {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }
}
