// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC721Custom.sol";

contract JaduJetpackStaking is Context {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsUnstaked;

    address payable public owner;
    address public JETPACK_CONTRACT;
    bool public stakingClosed = false;

    constructor(address _JETPACK_CONTRACT) {
        owner = payable(_msgSender());
        JETPACK_CONTRACT = _JETPACK_CONTRACT;
    }

    struct StakeItem {
        uint256 itemId;
        uint256 tokenId;
        address owner;
        uint256 time;
    }

    mapping(uint256 => bool) private NFTexist;
    mapping(uint256 => StakeItem) private idToStakeItem;
    mapping(uint256 => bool) public revealedIDs;

    modifier onlyOwner() {
        require(_msgSender() == owner, "You are not the contract owner.");
        _;
    }

    function closeStaking() public onlyOwner {
        stakingClosed = true;
    }

    function stakedItemsCount() public view returns (uint256) {
        return _itemIds._value;
    }

    function unstakedItemsCount() public view returns (uint256) {
        return _itemsUnstaked._value;
    }

    function stake(uint256 tokenId) public payable returns (uint256) {
        require(stakingClosed == false, "Jetpack Staking is closed.");

        require(NFTexist[tokenId] == false, "NFT already staked.");

        require(revealedIDs[tokenId] == false, "NFT was staked for 30 days.");

        NFTexist[tokenId] = true;

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToStakeItem[itemId] = StakeItem(
            itemId,
            tokenId,
            _msgSender(),
            block.timestamp
        );

        IERC721Custom(JETPACK_CONTRACT).transferFrom(
            _msgSender(),
            address(this),
            tokenId
        );

        return itemId;
    }

    function unStake(uint256 itemId) public payable returns (uint256) {
        uint256 tokenId = idToStakeItem[itemId].tokenId;
        require(
            idToStakeItem[itemId].owner == _msgSender() ||
                owner == _msgSender(),
            "You are not the owner of staked NFT."
        );

        if (block.timestamp > idToStakeItem[itemId].time + 30 days) {
            doReveal(tokenId);
        }

        uint256 id = tokenId;
        IERC721Custom(JETPACK_CONTRACT).transferFrom(
            address(this),
            _msgSender(),
            id
        );
        NFTexist[id] = false;
        delete idToStakeItem[itemId];
        _itemsUnstaked.increment();
        return tokenId;
    }

    function doReveal(uint256 tokenId) private {
        revealedIDs[tokenId] = true;
    }

    function multiUnStake(uint256[] calldata itemIds)
        public
        payable
        returns (bool)
    {
        for (uint256 i = 0; i < itemIds.length; i++) {
            unStake(itemIds[i]);
        }
        return true;
    }

    function fetchMyNFTs(address account)
        public
        view
        returns (StakeItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToStakeItem[i + 1].owner == account) {
                itemCount += 1;
            }
        }

        StakeItem[] memory items = new StakeItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToStakeItem[i + 1].owner == account) {
                uint256 currentId = i + 1;
                StakeItem storage currentItem = idToStakeItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}
