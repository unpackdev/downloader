// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/// @custom:security-contact yousuf.hossain.shanto@gmail.com
contract EscrowHub is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    enum EscrowState {
        AWAITING_DELIVERY,
        COMPLETED,
        CLAIMED_ON_EXPIRE,
        REFUNDED
    }

    struct Escrow {
        uint256 id;
        string cid;
        address payable buyer;
        address payable seller;
        uint256 amount;
        uint256 fee;
        uint256 createdAt;
        uint256 expireAt;
        uint256 clearAt;
        EscrowState state;
    }

    CountersUpgradeable.Counter private _escrowIds;
    mapping(uint256 => Escrow) private idToEscrow;
    mapping(address => uint256) private addressToEscrowCount;
    mapping(address => mapping(uint256 => uint256))
        private addressToEscrowIndexes;
    uint256 private constant _minimumEscrow = 0.03 ether;
    uint256 private constant _fee = 2; // Fee In Percent

    event EscrowCreated(
        uint256 indexed escrowId,
        string cid,
        address buyer,
        address seller,
        uint256 indexed amount,
        uint256 indexed fee,
        EscrowState state
    );

    event EscrowUpdated(
        uint256 indexed escrowId,
        string cid,
        address buyer,
        address seller,
        uint256 amount,
        uint256 fee,
        EscrowState indexed state
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // Custom Code Area Begins
    modifier onlyBuyer(uint256 escrowId) {
        require(
            idToEscrow[escrowId].buyer == msg.sender,
            "Only Buyer Can Access"
        );
        _;
    }

    modifier onlySeller(uint256 escrowId) {
        require(
            idToEscrow[escrowId].seller == msg.sender,
            "Only Seller Can Access"
        );
        _;
    }

    modifier notBuyer(uint256 escrowId) {
        require(
            idToEscrow[escrowId].seller == msg.sender || owner() == msg.sender,
            "Only seller or Owner can perform this action"
        );
        _;
    }

    function newEscrow(
        address _seller,
        string memory _cid,
        uint256 expireIn
    ) public payable nonReentrant {
        _escrowIds.increment();
        uint256 curId = _escrowIds.current();
        require(
            msg.value >= _minimumEscrow,
            "Escrow must be larger then minimum amount"
        );
        uint256 fee = (msg.value * _fee) / 100;
        uint256 _amount = msg.value - fee;
        idToEscrow[curId] = Escrow(
            curId,
            _cid,
            payable(msg.sender),
            payable(_seller),
            _amount,
            fee,
            block.timestamp,
            expireIn,
            0,
            EscrowState.AWAITING_DELIVERY
        );

        addressToEscrowCount[msg.sender] = addressToEscrowCount[msg.sender] + 1;
        addressToEscrowIndexes[msg.sender][
            addressToEscrowCount[msg.sender]
        ] = curId;
        addressToEscrowCount[_seller] = addressToEscrowCount[_seller] + 1;
        addressToEscrowIndexes[_seller][addressToEscrowCount[_seller]] = curId;

        emit EscrowCreated(
            curId,
            _cid,
            msg.sender,
            _seller,
            _amount,
            fee,
            EscrowState.AWAITING_DELIVERY
        );
    }

    function deliver(uint256 _escrowId)
        public
        onlyBuyer(_escrowId)
        nonReentrant
    {
        require(
            idToEscrow[_escrowId].state == EscrowState.AWAITING_DELIVERY,
            "You can't deliver this escrow. Already updated before"
        );

        idToEscrow[_escrowId].seller.transfer(idToEscrow[_escrowId].amount);
        payable(owner()).transfer(idToEscrow[_escrowId].fee);
        idToEscrow[_escrowId].clearAt = block.timestamp;
        idToEscrow[_escrowId].state = EscrowState.COMPLETED;

        emit EscrowUpdated(
            _escrowId,
            idToEscrow[_escrowId].cid,
            idToEscrow[_escrowId].buyer,
            idToEscrow[_escrowId].seller,
            idToEscrow[_escrowId].amount,
            idToEscrow[_escrowId].fee,
            EscrowState.COMPLETED
        );
    }

    function claimAfterExpire(uint256 _escrowId)
        public
        onlySeller(_escrowId)
        nonReentrant
    {
        require(
            idToEscrow[_escrowId].expireAt <= block.timestamp,
            "Escrow isn't expired yet"
        );
        require(
            idToEscrow[_escrowId].state == EscrowState.AWAITING_DELIVERY,
            "You can't claim this escrow. Already updated before"
        );

        idToEscrow[_escrowId].seller.transfer(idToEscrow[_escrowId].amount);
        payable(owner()).transfer(idToEscrow[_escrowId].fee);
        idToEscrow[_escrowId].clearAt = block.timestamp;
        idToEscrow[_escrowId].state = EscrowState.CLAIMED_ON_EXPIRE;

        emit EscrowUpdated(
            _escrowId,
            idToEscrow[_escrowId].cid,
            idToEscrow[_escrowId].buyer,
            idToEscrow[_escrowId].seller,
            idToEscrow[_escrowId].amount,
            idToEscrow[_escrowId].fee,
            EscrowState.CLAIMED_ON_EXPIRE
        );
    }

    function refund(uint256 _escrowId) public notBuyer(_escrowId) nonReentrant {
        require(
            idToEscrow[_escrowId].state == EscrowState.AWAITING_DELIVERY,
            "Can't refund this escrow. Already updated before"
        );

        idToEscrow[_escrowId].buyer.transfer(
            idToEscrow[_escrowId].amount + idToEscrow[_escrowId].fee
        );
        idToEscrow[_escrowId].clearAt = block.timestamp;
        idToEscrow[_escrowId].state = EscrowState.REFUNDED;

        emit EscrowUpdated(
            _escrowId,
            idToEscrow[_escrowId].cid,
            idToEscrow[_escrowId].buyer,
            idToEscrow[_escrowId].seller,
            idToEscrow[_escrowId].amount,
            idToEscrow[_escrowId].fee,
            EscrowState.REFUNDED
        );
    }

    /* Returns escrows based on roles */
    function fetchMyEscrows() public view returns (Escrow[] memory) {
        if (owner() == msg.sender) {
            uint256 totalItemCount = _escrowIds.current();
            Escrow[] memory items = new Escrow[](totalItemCount);
            for (uint256 i = 0; i < totalItemCount; i++) {
                items[i] = idToEscrow[i + 1];
            }
            return items;
        } else {
            // if signer is not owner
            Escrow[] memory items = new Escrow[](
                addressToEscrowCount[msg.sender]
            );
            for (uint256 i = 0; i < addressToEscrowCount[msg.sender]; i++) {
                items[i] = idToEscrow[
                    addressToEscrowIndexes[msg.sender][i + 1]
                ];
            }
            return items;
        }
    }

    function fetchEscrowsPaginated(uint256 cursor, uint256 perPageCount)
        public
        view
        returns (
            Escrow[] memory data,
            uint256 totalItemCount,
            bool hasNextPage,
            uint256 nextCursor
        )
    {
        uint256 length = perPageCount;
        if (owner() == msg.sender) {
            uint256 totalCount = _escrowIds.current();
            bool nextPage = true;
            if (length > totalCount - cursor) {
                length = totalCount - cursor;
                nextPage = false;
            } else if (length == (totalCount - cursor)) {
                nextPage = false;
            }
            Escrow[] memory items = new Escrow[](length);
            for (uint256 i = 0; i < length; i++) {
                items[i] = idToEscrow[cursor + i + 1];
            }
            return (items, totalCount, nextPage, (cursor + length));
        } else {
            bool nextPage = true;
            if (length > addressToEscrowCount[msg.sender] - cursor) {
                length = addressToEscrowCount[msg.sender] - cursor;
                nextPage = false;
            } else if (length == (addressToEscrowCount[msg.sender] - cursor)) {
                nextPage = false;
            }
            Escrow[] memory items = new Escrow[](length);
            for (uint256 i = 0; i < length; i++) {
                items[i] = idToEscrow[
                    addressToEscrowIndexes[msg.sender][cursor + i + 1]
                ];
            }
            return (
                items,
                addressToEscrowCount[msg.sender],
                nextPage,
                (cursor + length)
            );
        }
    }

    function fetchEscrow(uint256 escrowId) public view returns (Escrow memory) {
        return idToEscrow[escrowId];
    }
}
