//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./AccessControlMixin.sol";
import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./GoldFeverItemType.sol";

contract GoldFeverItemTier is ReentrancyGuard, AccessControlMixin {
    IERC721 nftContract;
    IERC20 ngl;
    address public itemTypeContract;

    constructor(
        address admin,
        address nftContract_,
        address nglContract_,
        address itemType_
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        nftContract = IERC721(nftContract_);
        ngl = IERC20(nglContract_);
        itemTypeContract = itemType_;
    }

    mapping(uint256 => uint256) public _tier;
    mapping(uint256 => mapping(uint256 => uint256))
        public itemTypeIdToTierUpgradePrice;
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256)))
        public itemTypeIdToTierAttribute;
    event TierAdded(
        uint256 indexed itemTypeId,
        uint256 tierId,
        uint256 upgradePrice
    );
    event ItemTierUpgraded(uint256 indexed itemId, uint256 tierId);
    event ItemUpgraded(uint256 indexed itemId, uint256 tierId);
    event TierAttributeUpdated(
        uint256 indexed itemTypeId,
        uint256 tierId,
        bytes32 attribute,
        uint256 value
    );

    function addTier(
        uint256 itemTypeId,
        uint256 tierId,
        uint256 upgradePrice
    ) public only(DEFAULT_ADMIN_ROLE) {
        require(tierId >= 2, "Tier must be greater than or equal to 2");
        itemTypeIdToTierUpgradePrice[itemTypeId][tierId] = upgradePrice;

        emit TierAdded(itemTypeId, tierId, upgradePrice);
    }

    function setItemTypeContract(address itemType_)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        itemTypeContract = itemType_;
    }

    function setItemTier(uint256 itemId, uint256 tierId)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        require(tierId >= 1, "Tier must be greater than or equal to 1");
        _tier[itemId] = tierId;
        emit ItemTierUpgraded(itemId, tierId);
    }

    function getItemTier(uint256 itemId) public view returns (uint256 tierId) {
        if (_tier[itemId] > 0) tierId = _tier[itemId];
        else tierId = 1;
    }

    function upgradeItem(uint256 itemId) public nonReentrant {
        require(
            IERC721(nftContract).ownerOf(itemId) == msg.sender,
            "You are not the item owner"
        );
        uint256 currentTier = getItemTier(itemId);
        uint256 itemTypeId = IGoldFeverItemType(itemTypeContract).getItemType(
            itemId
        );
        ngl.transferFrom(
            msg.sender,
            address(this),
            itemTypeIdToTierUpgradePrice[itemTypeId][currentTier + 1]
        );
        _tier[itemId] = currentTier + 1;
        emit ItemTierUpgraded(itemId, _tier[itemId]);
    }

    function setTierAttribute(
        uint256 itemTypeId,
        uint256 tierId,
        bytes32 attribute,
        uint256 value
    ) public only(DEFAULT_ADMIN_ROLE) {
        require(tierId >= 1, "Tier must be greater than or equal to 1");
        itemTypeIdToTierAttribute[itemTypeId][tierId][attribute] = value;
        emit TierAttributeUpdated(itemTypeId, tierId, attribute, value);
    }

    function getTierAttribute(
        uint256 itemTypeId,
        uint256 tierId,
        bytes32 attribute
    ) public view returns (uint256 value) {
        require(tierId >= 1, "Tier must be greater than or equal to 1");
        value = itemTypeIdToTierAttribute[itemTypeId][tierId][attribute];
    }

    function getItemAttribute(uint256 itemId, bytes32 attribute)
        public
        view
        returns (uint256 value)
    {
        uint256 itemTypeId = IGoldFeverItemType(itemTypeContract).getItemType(
            itemId
        );
        uint256 tierId = getItemTier(itemId);
        value = itemTypeIdToTierAttribute[itemTypeId][tierId][attribute];
    }

    function collectFee(address receivedAddress)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        ngl.transfer(receivedAddress, ngl.balanceOf(address(this)));
    }
}
