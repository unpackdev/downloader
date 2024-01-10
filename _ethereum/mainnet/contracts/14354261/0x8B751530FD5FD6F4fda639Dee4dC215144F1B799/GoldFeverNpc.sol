//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";

import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./AccessControlMixin.sol";

import "./GoldFeverItemTier.sol";
import "./GoldFeverNativeGold.sol";
import "./console.sol";

contract GoldFeverNpc is
    AccessControlMixin,
    IERC721Receiver,
    ERC721Holder,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    Counters.Counter private _hiringIds;
    uint256 private npcFee = 10 * (10**3);
    uint256 private npcEarning = 0;
    uint256 private rentPercentageLimit = 20 * (10**3);
    uint256 private ticketPercentageLimit = 20 * (10**3);
    bytes32 public constant STATUS_REQUESTED = keccak256("REQUESTED");
    bytes32 public constant STATUS_CREATED = keccak256("CREATED");
    bytes32 public constant STATUS_CANCELED = keccak256("CANCELED");

    bytes32 public constant OWNER_SLOTS = keccak256("OWNER_SLOTS");
    bytes32 public constant GUEST_SLOTS = keccak256("GUEST_SLOTS");

    bytes32 public constant TYPE_RENT = keccak256("TYPE_RENT");
    bytes32 public constant TYPE_TICKET = keccak256("TYPE_TICKET");

    IERC20 ngl;
    GoldFeverItemTier gfiTier;

    constructor(
        address admin,
        address ngl_,
        address gfiTier_
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        ngl = GoldFeverNativeGold(ngl_);
        gfiTier = GoldFeverItemTier(gfiTier_);
    }

    struct Hiring {
        uint256 hiringId;
        address nftContract;
        uint256 rentPercentage;
        uint256 ticketPercentage;
        uint256 buildingItem;
        address buildingOwner;
        bytes32 status;
    }

    struct RentableItem {
        uint256 hiringId;
        address itemOwner;
        uint256 hiringIdToItemsIndex;
        bytes32 status;
    }

    mapping(uint256 => Hiring) public idToHiring;
    mapping(uint256 => uint256[]) public hiringIdToItems;
    mapping(uint256 => mapping(uint256 => RentableItem))
        public hiringIdToRentableItem;
    mapping(address => uint256) public addressToPendingEarning;
    mapping(uint256 => uint256) public hiringIdToOwnerSlotsCount;
    mapping(uint256 => uint256) public hiringIdToGuestSlotsCount;

    event HiringCreated(
        uint256 indexed hiringId,
        address nftContract,
        uint256 rentPercentage,
        uint256 ticketPercentage,
        uint256 buildingItem,
        address buildingOwner
    );

    event ItemDeposited(
        uint256 indexed hiringId,
        address nftContract,
        address itemOwner,
        uint256 itemId
    );

    event HiringCanceled(uint256 indexed hiringId);

    event TicketFeeUpdated(uint256 hiringId, uint256 percentage);
    event RentFeeUpdated(uint256 hiringId, uint256 percentage);
    event EarningWithdrawn(address itemOwner, uint256 earning);
    event WithdrawRequested(
        uint256 hiringId,
        uint256 itemId,
        address itemOwner
    );
    event WithdrawApproved(uint256 hiringId, uint256 itemId, address itemOwner);

    event RentPaid(
        address renter,
        uint256 itemId,
        uint256 hiringId,
        uint256 amount
    );
    event TicketPaid(
        address renter,
        uint256 itemId,
        uint256 hiringId,
        uint256 amount
    );
    event BuildingServicePaid(address payer, uint256 hiringId, uint256 amount);

    function createHiring(address nftContract, uint256 buildingItem)
        public
        nonReentrant
    {
        _hiringIds.increment();
        uint256 hiringId = _hiringIds.current();
        //create new hiring with default percentage for both renting and tiketing limit

        idToHiring[hiringId] = Hiring(
            hiringId,
            nftContract,
            rentPercentageLimit,
            ticketPercentageLimit,
            buildingItem,
            msg.sender,
            STATUS_CREATED
        );

        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            buildingItem
        );

        emit HiringCreated(
            hiringId,
            nftContract,
            rentPercentageLimit,
            ticketPercentageLimit,
            buildingItem,
            msg.sender
        );
    }

    function depositItem(
        uint256 hiringId,
        address nftContract,
        uint256 itemId
    ) public nonReentrant {
        require(
            idToHiring[hiringId].status == STATUS_CREATED,
            "The building is already canceled !"
        );
        uint256 slots;
        bool isBuildingOwner;

        if (idToHiring[hiringId].buildingOwner == msg.sender) {
            slots = gfiTier.getItemAttribute(
                idToHiring[hiringId].buildingItem,
                OWNER_SLOTS
            );
            isBuildingOwner = true;
        } else {
            slots = gfiTier.getItemAttribute(
                idToHiring[hiringId].buildingItem,
                GUEST_SLOTS
            );
            isBuildingOwner = false;
        }
        uint256 count;

        if (isBuildingOwner) {
            count = hiringIdToOwnerSlotsCount[hiringId];
        } else {
            count = hiringIdToGuestSlotsCount[hiringId];
        }
        require(count < slots, "The building is at full capacity !");

        hiringIdToRentableItem[hiringId][itemId] = RentableItem(
            hiringId,
            msg.sender,
            hiringIdToItems[hiringId].length,
            STATUS_CREATED
        );

        if (isBuildingOwner) {
            hiringIdToOwnerSlotsCount[hiringId]++;
        } else {
            hiringIdToGuestSlotsCount[hiringId]++;
        }

        hiringIdToItems[hiringId].push(itemId);

        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            itemId
        );

        emit ItemDeposited(hiringId, nftContract, msg.sender, itemId);
    }

    function requestWithdrawal(uint256 hiringId, uint256 itemId)
        public
        nonReentrant
    {
        require(
            idToHiring[hiringId].status != STATUS_CANCELED,
            "The building is already canceled !"
        );
        require(
            hiringIdToRentableItem[hiringId][itemId].status == STATUS_CREATED,
            "Can not re-request withdrawal"
        );
        require(
            hiringIdToRentableItem[hiringId][itemId].itemOwner == msg.sender,
            "You are not the item owner"
        );

        hiringIdToRentableItem[hiringId][itemId].status = STATUS_REQUESTED;

        emit WithdrawRequested(
            hiringId,
            itemId,
            hiringIdToRentableItem[hiringId][itemId].itemOwner
        );
    }

    function approveWithdrawal(
        uint256 hiringId,
        uint256 itemId,
        address nftContract
    ) public only(DEFAULT_ADMIN_ROLE) {
        require(
            idToHiring[hiringId].status != STATUS_CANCELED,
            "The building is already canceled !"
        );
        require(
            hiringIdToRentableItem[hiringId][itemId].status == STATUS_REQUESTED,
            "Can not approve withdrawal on non-requested item"
        );

        address itemOwner = hiringIdToRentableItem[hiringId][itemId].itemOwner;
        uint256 currentItemIndex = hiringIdToRentableItem[hiringId][itemId]
            .hiringIdToItemsIndex;
        uint256 lastItemIndex = hiringIdToItems[hiringId].length - 1;
        if (addressToPendingEarning[itemOwner] > 0) {
            ngl.transfer(itemOwner, addressToPendingEarning[itemOwner]);
            addressToPendingEarning[itemOwner] = 0;
        }

        IERC721(nftContract).safeTransferFrom(address(this), itemOwner, itemId);

        if (idToHiring[hiringId].buildingOwner == itemOwner) {
            hiringIdToOwnerSlotsCount[hiringId]--;
        } else {
            hiringIdToGuestSlotsCount[hiringId]--;
        }

        if (currentItemIndex < lastItemIndex) {
            uint256 lastItemId = hiringIdToItems[hiringId][lastItemIndex];
            hiringIdToItems[hiringId][currentItemIndex] = lastItemId;
            hiringIdToRentableItem[hiringId][lastItemId]
                .hiringIdToItemsIndex = currentItemIndex;
        }
        hiringIdToItems[hiringId].pop();

        delete hiringIdToRentableItem[hiringId][itemId];

        emit WithdrawApproved(hiringId, itemId, itemOwner);
    }

    function withdrawEarning() public nonReentrant {
        ngl.transfer(msg.sender, addressToPendingEarning[msg.sender]);

        emit EarningWithdrawn(msg.sender, addressToPendingEarning[msg.sender]);

        addressToPendingEarning[msg.sender] = 0;
    }

    function payFee(
        address renter,
        uint256 itemId,
        uint256 hiringId,
        uint256 amount,
        bytes32 feeType
    ) public nonReentrant {
        require(
            idToHiring[hiringId].status == STATUS_CREATED,
            "The building is already canceled !"
        );
        require(
            feeType == TYPE_RENT || feeType == TYPE_TICKET,
            "Incorrect fee type"
        );

        uint256 decimal = 10**uint256(feeDecimals());
        uint256 percentage = feeType == TYPE_RENT
            ? idToHiring[hiringId].rentPercentage
            : idToHiring[hiringId].ticketPercentage;
        //Calculate contract and item owner earning
        uint256 npcEarn = (amount * npcFee) / decimal / 100;
        uint256 itemEarn = ((amount - npcEarn) * 100 * decimal) /
            (100 * decimal + percentage);

        //Add earning to array
        addressToPendingEarning[
            hiringIdToRentableItem[hiringId][itemId].itemOwner
        ] += itemEarn;

        addressToPendingEarning[idToHiring[hiringId].buildingOwner] += (amount -
            npcEarn -
            itemEarn);

        npcEarning += npcEarn;

        ngl.transferFrom(msg.sender, address(this), amount);

        if (feeType == TYPE_RENT)
            emit RentPaid(renter, itemId, hiringId, amount);
        else emit TicketPaid(renter, itemId, hiringId, amount);
    }

    function payBuildingServiceFee(
        address payer,
        uint256 hiringId,
        uint256 amount
    ) public nonReentrant {
        require(
            idToHiring[hiringId].status == STATUS_CREATED,
            "The building is already canceled !"
        );

        uint256 decimal = 10**uint256(feeDecimals());
        uint256 npcEarn = (amount * npcFee) / decimal / 100;

        addressToPendingEarning[idToHiring[hiringId].buildingOwner] += (amount -
            npcEarn);

        npcEarning += npcEarn;

        ngl.transferFrom(msg.sender, address(this), amount);

        emit BuildingServicePaid(payer, hiringId, amount);
    }

    function setTicketFee(uint256 hiringId, uint256 percentage)
        public
        nonReentrant
    {
        require(
            idToHiring[hiringId].status == STATUS_CREATED,
            "The building is already canceled !"
        );
        require(
            msg.sender == idToHiring[hiringId].buildingOwner,
            "You are not the building owner"
        );

        require(
            percentage <= ticketPercentageLimit,
            "The fee can't be set more than the limit !"
        );

        idToHiring[hiringId].ticketPercentage = percentage;

        emit TicketFeeUpdated(hiringId, percentage);
    }

    function setRentFee(uint256 hiringId, uint256 percentage)
        public
        nonReentrant
    {
        require(
            idToHiring[hiringId].status == STATUS_CREATED,
            "The building is already canceled !"
        );
        require(
            msg.sender == idToHiring[hiringId].buildingOwner,
            "You are not the building owner"
        );

        require(
            percentage <= rentPercentageLimit,
            "The fee can't be set more than the limit !"
        );

        idToHiring[hiringId].rentPercentage = percentage;

        emit RentFeeUpdated(hiringId, percentage);
    }

    function cancelHiring(uint256 hiringId, address nftContract)
        public
        nonReentrant
    {
        require(
            idToHiring[hiringId].buildingOwner == msg.sender,
            "You are not the building owner !"
        );
        require(
            idToHiring[hiringId].status == STATUS_CREATED,
            "The building is already canceled !"
        );

        ngl.transfer(msg.sender, addressToPendingEarning[msg.sender]);
        addressToPendingEarning[msg.sender] = 0;
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            idToHiring[hiringId].buildingItem
        );
        idToHiring[hiringId].status = STATUS_CANCELED;

        for (uint256 i = 0; i < hiringIdToItems[hiringId].length; i++) {
            address itemOwner = hiringIdToRentableItem[hiringId][
                hiringIdToItems[hiringId][i]
            ].itemOwner;
            ngl.transfer(itemOwner, addressToPendingEarning[itemOwner]);
            addressToPendingEarning[itemOwner] = 0;
            IERC721(nftContract).safeTransferFrom(
                address(this),
                itemOwner,
                hiringIdToItems[hiringId][i]
            );

            if (
                hiringIdToRentableItem[hiringId][hiringIdToItems[hiringId][i]]
                    .status == STATUS_REQUESTED
            )
                emit WithdrawApproved(
                    hiringId,
                    hiringIdToItems[hiringId][i],
                    itemOwner
                );
        }

        emit HiringCanceled(hiringId);
    }

    function getPendingEarning() public view returns (uint256 earning) {
        earning = addressToPendingEarning[msg.sender];
    }

    function getPercentageLimit()
        public
        view
        returns (uint256 rentLimit, uint256 ticketLimit)
    {
        rentLimit = rentPercentageLimit;
        ticketLimit = ticketPercentageLimit;
    }

    function setNpcFee(uint256 percentage) public only(DEFAULT_ADMIN_ROLE) {
        npcFee = percentage;
    }

    function setRentPercentageLimit(uint256 percentage)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        rentPercentageLimit = percentage;
    }

    function setTicketPercentageLimit(uint256 percentage)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        ticketPercentageLimit = percentage;
    }

    function withdrawNpcFee(address receivedAddress)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        ngl.transfer(receivedAddress, npcEarning);
        npcEarning = 0;
    }

    function setGoldFeverItemTierContract(address gfiTierAddress)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        gfiTier = GoldFeverItemTier(gfiTierAddress);
    }

    function feeDecimals() public pure returns (uint8) {
        return 3;
    }
}
