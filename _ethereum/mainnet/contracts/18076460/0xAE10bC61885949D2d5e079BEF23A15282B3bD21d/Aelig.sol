// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ERC721Metadata.sol";
import "./TokenReceiver.sol";
import "./Withdraw.sol";
import "./ERC2981.sol";
import "./IAelig.sol";

contract Aelig is
    IAelig,
    ERC165,
    ERC721Metadata,
    TokenReceiver,
    Withdraw,
    ERC2981
{
    address public store;
    address public tags;
    mapping(uint256=>uint256) private idToModel;

    constructor(
        uint256 royaltyPercentage,
        address _store,
        address _tags
    )
        ERC2981(royaltyPercentage)
    {
        store = _store;
        tags = _tags;
    }

    modifier isAdminOrStore(address account) {
        require(
            account == manager ||
            addressToAdmin[account] ||
            account == store,
            errors.NOT_AUTHORIZED
        );
        _;
    }

    function updateStore(address _store)
        external
        override
        isAdmin(msg.sender)
    {
        store = _store;
        emit StoreUpdated(_store);
    }

    function getModel(uint256 frameId)
        external
        view
        override
        validNFToken(frameId)
        returns(uint256)
    {
        return idToModel[frameId];
    }

    function newFrames(uint256 model, address receiver, uint256 quantity)
        external
        override
        isAdminOrStore(msg.sender)
    {
        for (uint i = 0; i < quantity; i++) {
            uint256 newId = mintedFrames();
            _mint(receiver, newId);
            emit FramesCreated(model, newId, receiver);
        }
    }

    function updateTags(address _tags)
        external
        override
        isAdmin(msg.sender)
    {
        tags = _tags;
        emit TagsUpdated(_tags);
    }

}
