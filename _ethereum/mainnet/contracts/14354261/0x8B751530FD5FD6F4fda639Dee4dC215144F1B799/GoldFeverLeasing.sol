//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";

contract GoldFeverLeasing is ReentrancyGuard, IERC721Receiver, ERC721Holder {
    bytes32 public constant STATUS_CREATED = keccak256("STATUS_CREATED");
    bytes32 public constant STATUS_CANCELED = keccak256("STATUS_CANCELED");
    bytes32 public constant STATUS_RENT = keccak256("STATUS_RENT");
    bytes32 public constant STATUS_FINISHED = keccak256("STATUS_FINISHED");

    uint256 public constant build = 3;

    using Counters for Counters.Counter;
    Counters.Counter private _leaseIds;

    IERC20 ngl;

    constructor(address ngl_) public {
        ngl = IERC20(ngl_);
    }

    struct Lease {
        uint256 leaseId;
        address nftContract;
        uint256 tokenId;
        address owner;
        uint256 price;
        bytes32 status;
        uint256 duration;
    }

    mapping(uint256 => Lease) public idToLeaseItem;
    mapping(uint256 => uint256) public idToExpiry;
    mapping(uint256 => address) public idToRenter;

    event LeaseCreated(
        uint256 indexed leaseId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint256 duration
    );
    event LeaseCanceled(uint256 indexed leaseId);
    event LeaseFinished(uint256 indexed leaseId);
    event LeaseRent(
        uint256 indexed leaseId,
        address indexed renter,
        uint256 expiry
    );

    function createItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 duration
    ) public nonReentrant {
        require(price > 0, "Price must be at least 1 wei");

        _leaseIds.increment();
        uint256 leaseId = _leaseIds.current();

        idToLeaseItem[leaseId] = Lease(
            leaseId,
            nftContract,
            tokenId,
            msg.sender,
            price,
            STATUS_CREATED,
            duration
        );

        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit LeaseCreated(
            leaseId,
            nftContract,
            tokenId,
            msg.sender,
            price,
            duration
        );
    }

    function cancelItem(uint256 leaseId) public nonReentrant {
        require(idToLeaseItem[leaseId].owner == msg.sender, "Not leasor");
        require(
            idToLeaseItem[leaseId].status == STATUS_CREATED,
            "Item is not for sale"
        );
        address owner = idToLeaseItem[leaseId].owner;
        uint256 tokenId = idToLeaseItem[leaseId].tokenId;
        address nftContract = idToLeaseItem[leaseId].nftContract;
        IERC721(nftContract).safeTransferFrom(address(this), owner, tokenId);
        emit LeaseCanceled(leaseId);
        idToLeaseItem[leaseId].status = STATUS_CANCELED;
    }

    function rentItem(uint256 leaseId) public nonReentrant {
        require(
            idToLeaseItem[leaseId].status == STATUS_CREATED,
            "Item is not for sale"
        );
        uint256 price = idToLeaseItem[leaseId].price;
        address owner = idToLeaseItem[leaseId].owner;
        uint256 duration = idToLeaseItem[leaseId].duration;

        uint256 expiry = block.timestamp + duration;
        idToRenter[leaseId] = msg.sender;
        idToExpiry[leaseId] = expiry;

        ngl.transferFrom(msg.sender, owner, price);
        emit LeaseRent(leaseId, msg.sender, expiry);
        idToLeaseItem[leaseId].status = STATUS_RENT;
    }

    function finalizeLeaseItem(uint256 leaseId) public nonReentrant {
        require(
            idToLeaseItem[leaseId].status == STATUS_RENT,
            "Item is not on lease"
        );
        require(
            idToExpiry[leaseId] <= block.timestamp,
            "Lease is not finished"
        );
        require(idToLeaseItem[leaseId].owner == msg.sender, "Not leaser");

        address owner = idToLeaseItem[leaseId].owner;
        uint256 tokenId = idToLeaseItem[leaseId].tokenId;
        address nftContract = idToLeaseItem[leaseId].nftContract;

        IERC721(nftContract).safeTransferFrom(address(this), owner, tokenId);
        emit LeaseFinished(leaseId);
        idToLeaseItem[leaseId].status = STATUS_FINISHED;
    }
}
