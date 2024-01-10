//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";

import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";

contract GoldFeverSwap is IERC721Receiver, ERC721Holder, ReentrancyGuard {
    bytes32 public constant STATUS_CREATED = keccak256("STATUS_CREATED");
    bytes32 public constant STATUS_SWAPPED = keccak256("STATUS_SWAPPED");
    bytes32 public constant STATUS_CANCELED = keccak256("STATUS_CANCELED");
    bytes32 public constant STATUS_REJECTED = keccak256("STATUS_REJECTED");

    uint256 public constant build = 3;

    using Counters for Counters.Counter;
    Counters.Counter private _offerIds;

    IERC20 ngl;

    constructor(address ngl_) public {
        ngl = IERC20(ngl_);
    }

    struct Offer {
        uint256 offerId;
        address nftContract;
        address fromAddress;
        uint256[] fromNftIds;
        uint256 fromNglAmount;
        address toAddress;
        uint256[] toNftIds;
        uint256 toNglAmount;
        bytes32 status;
    }

    mapping(uint256 => Offer) public idToOffer;

    event OfferCreated(
        uint256 indexed OfferId,
        address nftContract,
        address fromAddress,
        uint256[] fromNftIds,
        uint256 fromNglAmount,
        address toAddress,
        uint256[] toNftIds,
        uint256 toNglAmount
    );
    event OfferCanceled(uint256 indexed offerId);
    event OfferRejected(uint256 indexed offerId);
    event OfferSwapped(uint256 indexed offerId, address indexed buyer);

    function createOffer(
        address nftContract,
        uint256[] memory fromNftIds,
        uint256 fromNglAmount,
        uint256[] memory toNftIds,
        uint256 toNglAmount,
        address toAddress
    ) public nonReentrant {
        _offerIds.increment();
        uint256 offerId = _offerIds.current();

        idToOffer[offerId] = Offer(
            offerId,
            nftContract,
            msg.sender,
            fromNftIds,
            fromNglAmount,
            toAddress,
            toNftIds,
            toNglAmount,
            STATUS_CREATED
        );
        ngl.transferFrom(msg.sender, address(this), fromNglAmount);
        for (uint256 i = 0; i < fromNftIds.length; i++) {
            IERC721(nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                fromNftIds[i]
            );
        }

        emit OfferCreated(
            offerId,
            nftContract,
            msg.sender,
            fromNftIds,
            fromNglAmount,
            toAddress,
            toNftIds,
            toNglAmount
        );
    }

    function cancelOffer(uint256 offerId) public nonReentrant {
        require(idToOffer[offerId].fromAddress == msg.sender, "Not seller");
        require(
            idToOffer[offerId].status == STATUS_CREATED,
            "Offer is not for swap"
        );
        address fromAddress = idToOffer[offerId].fromAddress;
        uint256[] memory fromNftIds = idToOffer[offerId].fromNftIds;
        uint256 fromNglAmount = idToOffer[offerId].fromNglAmount;
        address nftContract = idToOffer[offerId].nftContract;
        ngl.transfer(fromAddress, fromNglAmount);
        for (uint256 i = 0; i < fromNftIds.length; i++) {
            IERC721(nftContract).safeTransferFrom(
                address(this),
                fromAddress,
                fromNftIds[i]
            );
        }
        idToOffer[offerId].status = STATUS_CANCELED;
        emit OfferCanceled(offerId);
    }

    function rejectOffer(uint256 offerId) public nonReentrant {
        require(idToOffer[offerId].toAddress == msg.sender, "Not buyer");
        require(
            idToOffer[offerId].status == STATUS_CREATED,
            "Offer is not for swap"
        );
        address fromAddress = idToOffer[offerId].fromAddress;
        uint256[] memory fromNftIds = idToOffer[offerId].fromNftIds;
        uint256 fromNglAmount = idToOffer[offerId].fromNglAmount;
        address nftContract = idToOffer[offerId].nftContract;
        ngl.transfer(fromAddress, fromNglAmount);
        for (uint256 i = 0; i < fromNftIds.length; i++) {
            IERC721(nftContract).safeTransferFrom(
                address(this),
                fromAddress,
                fromNftIds[i]
            );
        }
        idToOffer[offerId].status = STATUS_REJECTED;
        emit OfferRejected(offerId);
    }

    function acceptOffer(uint256 offerId) public nonReentrant {
        require(
            idToOffer[offerId].status == STATUS_CREATED,
            "Offer is not for swap"
        );
        require(
            idToOffer[offerId].toAddress == msg.sender,
            "You are not the offered address"
        );
        address fromAddress = idToOffer[offerId].fromAddress;
        uint256[] memory fromNftIds = idToOffer[offerId].fromNftIds;
        uint256 fromNglAmount = idToOffer[offerId].fromNglAmount;
        uint256[] memory toNftIds = idToOffer[offerId].toNftIds;
        uint256 toNglAmount = idToOffer[offerId].toNglAmount;
        address nftContract = idToOffer[offerId].nftContract;

        ngl.transferFrom(msg.sender, fromAddress, toNglAmount);
        for (uint256 i = 0; i < toNftIds.length; i++) {
            IERC721(nftContract).safeTransferFrom(
                msg.sender,
                fromAddress,
                toNftIds[i]
            );
        }
        ngl.transfer(msg.sender, fromNglAmount);
        for (uint256 i = 0; i < fromNftIds.length; i++) {
            IERC721(nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                fromNftIds[i]
            );
        }
        idToOffer[offerId].status = STATUS_SWAPPED;
        emit OfferSwapped(offerId, msg.sender);
    }

    function getOffer(uint256 offerId)
        public
        view
        returns (
            address fromAddress,
            uint256[] memory fromNftIds,
            uint256 fromNglAmount,
            uint256[] memory toNftIds,
            uint256 toNglAmount,
            address toAddress,
            string memory status
        )
    {
        Offer memory offer = idToOffer[offerId];
        if (offer.status == keccak256("STATUS_CREATED")) {
            status = "CREATED";
        } else if (offer.status == keccak256("STATUS_CANCELED")) {
            status = "CANCELED";
        } else if (offer.status == keccak256("STATUS_REJECTED")) {
            status = "REJECTED";
        } else {
            status = "SWAPPED";
        }

        fromAddress = offer.fromAddress;
        fromNftIds = offer.fromNftIds;
        fromNglAmount = offer.fromNglAmount;
        toNftIds = offer.toNftIds;
        toNglAmount = offer.toNglAmount;
        toAddress = offer.toAddress;
    }
}
