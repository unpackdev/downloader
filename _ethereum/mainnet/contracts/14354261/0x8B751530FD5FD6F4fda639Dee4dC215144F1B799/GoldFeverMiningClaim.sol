//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./AccessControlMixin.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./GoldFeverNativeGold.sol";
import "./GoldFeverItem.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";

contract GoldFeverMiningClaim is
    ReentrancyGuard,
    AccessControlMixin,
    IERC721Receiver,
    ERC721Holder
{
    bytes32 public constant ARENA_STARTED = keccak256("ARENA_STARTED");
    bytes32 public constant ARENA_CLOSED = keccak256("ARENA_CLOSED");

    bytes32 public constant MINER_REGISTERED = keccak256("MINER_REGISTERED");
    bytes32 public constant MINER_UNREGISTERED =
        keccak256("MINER_UNREGISTERED");
    bytes32 public constant MINER_ENTERED = keccak256("MINER_ENTERED");
    bytes32 public constant MINER_LEFT = keccak256("MINER_LEFT");

    bytes32 public constant MINING_CLAIM_CREATED =
        keccak256("MINING_CLAIM_CREATED");

    using Counters for Counters.Counter;

    Counters.Counter private _arenaIds;
    GoldFeverNativeGold ngl;
    GoldFeverItem gfi;
    address nftContract;
    uint256 private nglFromSellingHour = 0;
    uint256 private miningSpeed = 100;
    uint256 public arenaHourPrice;

    constructor(
        address admin,
        address gfiContract_,
        address nglContract_
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        gfi = GoldFeverItem(gfiContract_);
        ngl = GoldFeverNativeGold(nglContract_);
        nftContract = gfiContract_;
        uint256 decimals = ngl.decimals();
        arenaHourPrice = 200 * (10**decimals);
    }

    struct MiningClaim {
        uint256 miningClaimId;
        uint256 arenaHour;
        uint256 nglAmount;
        uint256 maxMiners;
        bytes32 status;
    }

    struct Arena {
        uint256 arenaId;
        address owner;
        uint256 miningClaimId;
        uint256 numMinersInArena;
        bytes32 status;
        uint256 duration;
        uint256 upfrontFee;
        uint256 commissionRate;
    }

    struct Miner {
        uint256 arenaId;
        address minerAddress;
        bytes32 status;
    }

    mapping(uint256 => MiningClaim) public idToMiningClaim;
    mapping(uint256 => Arena) public idToArena;
    mapping(uint256 => uint256) public arenaIdToExpiry;
    mapping(uint256 => mapping(address => Miner)) public idToMinerByArena;

    event MiningClaimCreated(
        uint256 indexed miningClaimId,
        uint256 arenaHour,
        uint256 nglAmount,
        uint256 maxMiners,
        address nftContract
    );

    event ArenaStarted(
        uint256 indexed arenaId,
        address indexed owner,
        uint256 indexed miningClaimId,
        uint256 numMinersInArena,
        bytes32 status,
        uint256 duration,
        uint256 expiry,
        uint256 upfrontFee,
        uint256 commissionRate
    );
    event ArenaClosed(uint256 arenaId);

    event MinerRegistered(
        uint256 arenaId,
        address minerAddress,
        bytes32 status
    );

    event MinerCanceledRegistration(
        uint256 arenaId,
        address minerAddress,
        bytes32 status
    );
    event MinerEnteredArena(
        uint256 arenaId,
        address minerAddress,
        bytes32 status
    );

    event MinerLeftArena(uint256 arenaId, address minerAddress, bytes32 status);

    event MinerWithdrawn(
        uint256 arenaId,
        address minerAddress,
        uint256 nglAmount
    );

    event Supplied(uint256 miningClaimId, uint256 nglAmount);

    event AddArenaHour(uint256 miningClaimId, uint256 arenaHour);

    event SetArenaHour(uint256 miningClaimId, uint256 arenaHour);

    event BuyArenaHour(uint256 miningClaimId, uint256 arenaHour);

    event SetMaxMiners(uint256 miningClaimId, uint256 maxMiners);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    function createMiningClaim(
        uint256 miningClaimId,
        uint256 nglAmount,
        uint256 arenaHour,
        uint256 maxMiners
    ) public nonReentrant onlyAdmin {
        require(
            gfi.ownerOf(miningClaimId) != address(0),
            "Mining claim id does not exist"
        );
        require(
            idToMiningClaim[miningClaimId].status != MINING_CLAIM_CREATED,
            "Mining claim already created"
        );
        ngl.transferFrom(msg.sender, address(this), nglAmount);

        idToMiningClaim[miningClaimId] = MiningClaim(
            miningClaimId,
            arenaHour,
            nglAmount,
            maxMiners,
            MINING_CLAIM_CREATED
        );

        emit MiningClaimCreated(
            miningClaimId,
            arenaHour,
            nglAmount,
            maxMiners,
            nftContract
        );
    }

    function supply(uint256 miningClaimId, uint256 nglAmount) public onlyAdmin {
        require(
            idToMiningClaim[miningClaimId].status == MINING_CLAIM_CREATED,
            "Mining claim id does not exist"
        );
        ngl.transferFrom(msg.sender, address(this), nglAmount);
        idToMiningClaim[miningClaimId].nglAmount += nglAmount;
        emit Supplied(miningClaimId, nglAmount);
    }

    function addArenaHour(uint256 miningClaimId, uint256 arenaHour)
        public
        onlyAdmin
    {
        idToMiningClaim[miningClaimId].arenaHour += arenaHour;
        emit AddArenaHour(miningClaimId, arenaHour);
    }

    function setArenaHour(uint256 miningClaimId, uint256 arenaHour)
        public
        onlyAdmin
    {
        idToMiningClaim[miningClaimId].arenaHour = arenaHour;
        emit SetArenaHour(miningClaimId, arenaHour);
    }

    function getArenaHour(uint256 miningClaimId) public view returns (uint256) {
        return idToMiningClaim[miningClaimId].arenaHour;
    }

    function setArenaHourPrice(uint256 _arenaHourPrice)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        arenaHourPrice = _arenaHourPrice;
    }

    function getArenaHourPrice() public view returns (uint256) {
        uint256 decimals = ngl.decimals();
        return arenaHourPrice / (10**decimals);
    }

    function buyArenaHour(uint256 miningClaimId, uint256 arenaHour)
        public
        nonReentrant
    {
        require(
            gfi.ownerOf(miningClaimId) == msg.sender,
            "Only owner of mining claim can buy arena hour"
        );
        uint256 price = arenaHour * arenaHourPrice;
        nglFromSellingHour += price;
        ngl.transferFrom(msg.sender, address(this), price);
        idToMiningClaim[miningClaimId].arenaHour += arenaHour;
        emit BuyArenaHour(miningClaimId, arenaHour);
    }

    function getMiningSpeed() public view onlyAdmin returns (uint256) {
        return miningSpeed;
    }

    function setMiningSpeed(uint256 _miningSpeed) public onlyAdmin {
        miningSpeed = _miningSpeed;
    }

    function getMaxMiners(uint256 miningClaimId)
        public
        view
        onlyAdmin
        returns (uint256 maxMiners)
    {
        maxMiners = idToMiningClaim[miningClaimId].maxMiners;
    }

    function setMaxMiners(uint256 miningClaimId, uint256 maxMiners)
        public
        onlyAdmin
    {
        idToMiningClaim[miningClaimId].maxMiners = maxMiners;
        emit SetMaxMiners(miningClaimId, maxMiners);
    }

    function startArena(
        uint256 miningClaimId,
        uint256 duration,
        uint256 upfrontFee,
        uint256 commissionRate
    ) public nonReentrant {
        require(
            gfi.ownerOf(miningClaimId) == msg.sender,
            "Only owner of mining claim can start arena"
        );
        require(
            duration <= idToMiningClaim[miningClaimId].arenaHour,
            "Arena open duration must be less than or equal to arena total hour"
        );
        require(duration > 0, "Arena open duration must be greater than 0");

        _arenaIds.increment();
        uint256 arenaId = _arenaIds.current();
        uint256 expiry = (duration * 3600) + block.timestamp;
        arenaIdToExpiry[arenaId] = expiry;

        idToArena[arenaId] = Arena(
            arenaId,
            msg.sender,
            miningClaimId,
            0,
            ARENA_STARTED,
            duration,
            upfrontFee,
            commissionRate
        );
        idToMiningClaim[miningClaimId].arenaHour -= duration;
        gfi.safeTransferFrom(msg.sender, address(this), miningClaimId);

        emit ArenaStarted(
            arenaId,
            msg.sender,
            miningClaimId,
            0,
            ARENA_STARTED,
            duration,
            expiry,
            upfrontFee,
            commissionRate
        );
    }

    function closeArena(uint256 arenaId) public nonReentrant onlyAdmin {
        require(
            arenaIdToExpiry[arenaId] <= block.timestamp,
            "Arena is not finished"
        );
        uint256 miningClaimId = idToArena[arenaId].miningClaimId;
        idToArena[arenaId].status = ARENA_CLOSED;
        gfi.safeTransferFrom(
            address(this),
            idToArena[arenaId].owner,
            miningClaimId
        );
        emit ArenaClosed(arenaId);
    }

    function registerAtArena(uint256 arenaId) public nonReentrant {
        uint256 miningClaimId = idToArena[arenaId].miningClaimId;
        require(
            idToArena[arenaId].status == ARENA_STARTED,
            "Arena is not started"
        );
        require(
            idToArena[arenaId].numMinersInArena <
                idToMiningClaim[miningClaimId].maxMiners,
            "Arena is full"
        );
        uint256 upfrontFee = idToArena[arenaId].upfrontFee;

        idToMinerByArena[arenaId][msg.sender] = Miner(
            arenaId,
            msg.sender,
            MINER_REGISTERED
        );

        ngl.transferFrom(msg.sender, address(this), upfrontFee);

        emit MinerRegistered(arenaId, msg.sender, MINER_REGISTERED);
    }

    function cancelArenaRegistration(uint256 arenaId) public nonReentrant {
        require(
            idToMinerByArena[arenaId][msg.sender].status == MINER_REGISTERED,
            "Miner already entered arena"
        );
        uint256 upfrontFee = idToArena[arenaId].upfrontFee;
        delete idToMinerByArena[arenaId][msg.sender];
        ngl.transfer(msg.sender, upfrontFee);
        emit MinerCanceledRegistration(arenaId, msg.sender, MINER_UNREGISTERED);
    }

    function enterArena(uint256 arenaId, address minerAddress)
        public
        nonReentrant
        onlyAdmin
    {
        require(
            idToMinerByArena[arenaId][minerAddress].status == MINER_REGISTERED,
            "Miner not registered"
        );
        require(
            idToArena[arenaId].status == ARENA_STARTED,
            "Arena is not started"
        );
        uint256 upfrontFee = idToArena[arenaId].upfrontFee;

        address owner = idToArena[arenaId].owner;

        ngl.transfer(owner, upfrontFee);
        idToArena[arenaId].numMinersInArena++;
        idToMinerByArena[arenaId][minerAddress].status = MINER_ENTERED;

        emit MinerEnteredArena(arenaId, minerAddress, MINER_ENTERED);
    }

    function leaveArena(uint256 arenaId, address minerAddress)
        public
        nonReentrant
        onlyAdmin
    {
        require(
            idToMinerByArena[arenaId][minerAddress].status == MINER_ENTERED,
            "Miner not entered arena"
        );
        delete idToMinerByArena[arenaId][minerAddress];
        idToArena[arenaId].numMinersInArena--;
        emit MinerLeftArena(arenaId, minerAddress, MINER_LEFT);
    }

    function bankWithdraw(
        uint256 arenaId,
        address minerAddress,
        uint256 nglAmount
    ) public nonReentrant onlyAdmin {
        uint256 miningClaimId = idToArena[arenaId].miningClaimId;
        uint256 arenaDuration = idToArena[arenaId].duration;
        uint256 maxMiners = idToMiningClaim[miningClaimId].maxMiners;
        uint256 maxNglAmountCanWithdraw = arenaDuration *
            maxMiners *
            miningSpeed;
        uint256 totalNglAmount = idToMiningClaim[miningClaimId].nglAmount;
        require(nglAmount > 0, "Amount must be greater than 0");
        require(
            nglAmount <= maxNglAmountCanWithdraw,
            "Amount must be less than or equal to max amount"
        );
        require(
            nglAmount <= totalNglAmount,
            "Amount must be less than or equal to total amount"
        );
        uint256 decimal = 10**uint256(feeDecimals());
        uint256 commissionRate = idToArena[arenaId].commissionRate;
        uint256 ownerEarn = (nglAmount * commissionRate) / decimal / 100;
        ngl.transfer(idToArena[arenaId].owner, ownerEarn);
        ngl.transfer(minerAddress, nglAmount - ownerEarn);
        emit MinerWithdrawn(arenaId, minerAddress, nglAmount - ownerEarn);
    }

    function feeDecimals() public pure returns (uint8) {
        return 3;
    }

    function withdrawNglFromSellingHour() public nonReentrant onlyAdmin {
        ngl.transfer(msg.sender, nglFromSellingHour);
        nglFromSellingHour = 0;
    }
}
