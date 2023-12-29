// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";

import "./LinearVRGDA.sol";
import "./ERC721.sol";
import "./SafeTransferLib.sol";
import "./SignedWadMath.sol";
import "./KomodosRoost.sol";

contract KomodosRoostNest is LinearVRGDA, Ownable, ERC721TokenReceiver {
    KomodosRoost public roost;

    uint256 private soldQty = 0;
    uint256 private startTime = 0;

    uint256 private randNonce;

    uint256 private constant MAX_ORDER_QTY = 50;
    uint256 private constant MAX_SALE_ALLOCATION = 1069;

    uint256 private constant MIN_KOMODO_RANK = 4;
    uint256 private constant MAX_KOMODO_RANK = 10;
    uint256 private constant GILA_KOMODO_RANK = 150;

    mapping(uint256 => NestState) private nestStates;
    mapping(address => uint256[]) private allNestedEggs;
    uint256[] private komodoIdsRankWeighted;

    bool public nestingActive = false;

    struct NestState {
        uint256 nestedTill;
        uint256 nestedFor;
        address nestedBy;
        // 0 => unhatched
        // MIN_KOMODO_RANK <=> MAX_KOMODO_RANK => hatched
        uint256 rank;
    }

    event FundsAssigned(uint256 timestamp);
    event EggMinted(uint256 indexed eggId, address indexed mintedTo);
    event EggNested(
        uint256 indexed eggId,
        address indexed nestedBy,
        uint256 nestedFor
    );
    event EggStolen(
        uint256 indexed eggId,
        address indexed stolenFrom,
        address indexed stolenBy,
        uint256 stolenByKomodo
    );
    event EggHatched(
        uint256 indexed eggId,
        address indexed hatchedBy,
        uint256 rank
    );

    modifier onlyGilaKomodo() {
        require(
            msg.sender == roost.ownerOf(0),
            "Only the Legion of Gila may enter"
        );
        _;
    }

    constructor(
        address _roostAddress,
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _perTimeUnit,
        uint256 _entropy
    ) LinearVRGDA(_targetPrice, _priceDecayPercent, _perTimeUnit) {
        roost = KomodosRoost(_roostAddress);
        randNonce = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.number,
                    block.coinbase,
                    block.prevrandao,
                    block.timestamp,
                    _entropy
                )
            )
        );

        _transferOwnership(roost.courtAddress());
    }

    function awaken() external onlyOwner {
        require(startTime == 0, "ALREADY_AWAKE");
        address courtAddress = roost.courtAddress();
        nestStates[0] = NestState(0, 0, courtAddress, GILA_KOMODO_RANK);
        emit EggHatched(0, courtAddress, GILA_KOMODO_RANK);
        nestStates[1] = NestState(0, 0, courtAddress, MAX_KOMODO_RANK);
        emit EggHatched(1, courtAddress, MAX_KOMODO_RANK);
        for (uint256 i = 0; i < GILA_KOMODO_RANK; i++) {
            komodoIdsRankWeighted.push(0);
        }
        for (uint256 i = 0; i < MAX_KOMODO_RANK; i++) {
            komodoIdsRankWeighted.push(1);
        }
        nestingActive = true;
        startTime = block.timestamp;
    }

    function disableNesting() external onlyOwner {
        nestingActive = false;
    }

    function getPrice() public view returns (uint256) {
        return
            getVRGDAPrice(
                toDaysWadUnsafe(block.timestamp - startTime),
                soldQty
            );
    }

    function mint(
        uint256 quantity
    ) external payable returns (uint256 unitPrice) {
        require(nestingActive, "NESTING_INACTIVE");
        require(block.timestamp >= startTime, "SALE_INACTIVE");
        require(soldQty + quantity <= MAX_SALE_ALLOCATION, "SUPPLY_EXHAUSTED");
        require(quantity > 0 && quantity <= MAX_ORDER_QTY, "ORDER_QTY_INVALID");

        unchecked {
            unitPrice = getPrice();
            uint256 totalPrice = quantity * unitPrice;
            require(msg.value >= totalPrice, "UNDERPAID"); // Don't allow underpaying.

            soldQty += quantity;
            for (uint256 i = 0; i < quantity; i++) {
                roost.mint(msg.sender);
                emit EggMinted(roost.nextToMint() - 1, msg.sender);
            }

            // Note: We do this at the end to avoid creating a reentrancy vector.
            // Refund the user any ETH they spent over the current price of the eggs.
            // Unchecked is safe here because we validate msg.value >= price above.
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - totalPrice);
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
        emit FundsAssigned(block.timestamp);
    }

    function isNestable(uint256 eggId) public view returns (bool) {
        return
            (nestStates[eggId].rank == 0) &&
            (nestStates[eggId].nestedTill == 0) &&
            roost.exists(eggId);
    }

    function nest(uint256 eggId, uint256 rank) public {
        require(nestingActive, "NESTING_INACTIVE");
        require(roost.ownerOf(eggId) == msg.sender, "NOT_THE_EGG_OWNER");
        require(nestStates[eggId].rank == 0, "EGG_ALREADY_HATCHED");
        require(nestStates[eggId].nestedTill == 0, "EGG_ALREADY_NESTED");
        require(
            rank >= MIN_KOMODO_RANK && rank <= MAX_KOMODO_RANK,
            "INVALID_RANK"
        );

        uint256 nestingBlocks = calculateNestingBlocks(rank);

        // Set the nestedTill field of the egg struct to the block number when the egg will be ready to hatch
        nestStates[eggId] = NestState(
            block.number + nestingBlocks,
            nestingBlocks,
            msg.sender,
            0
        );
        allNestedEggs[msg.sender].push(eggId);
        emit EggNested(eggId, msg.sender, nestingBlocks);

        // Transfer the egg from the caller to the contract
        // NOTE: Transfer is done at the end to avoid a re-entrancy vector
        roost.safeTransferFrom(msg.sender, address(this), eggId);
    }

    function nestAll(uint256[] calldata eggIds, uint256 rank) public {
        for (uint256 i = 0; i < eggIds.length; ++i) {
            nest(eggIds[i], rank);
        }
    }

    function getPendingEggs(
        address nester
    ) public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allNestedEggs[nester].length; i++) {
            uint256 eggId = allNestedEggs[nester][i];
            NestState storage nestState = nestStates[eggId];

            if (
                nestState.nestedTill != 0 && block.number < nestState.nestedTill
            ) {
                ++count;
            }
        }

        uint256 idx = 0;
        uint256[] memory eggIds = new uint256[](count);
        for (uint256 i = 0; i < allNestedEggs[nester].length; i++) {
            uint256 eggId = allNestedEggs[nester][i];
            NestState storage nestState = nestStates[eggId];

            if (
                nestState.nestedTill != 0 && block.number < nestState.nestedTill
            ) {
                eggIds[idx++] = eggId;
            }
        }
        return eggIds;
    }

    function getHatchableEggs(
        address nester
    ) public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allNestedEggs[nester].length; i++) {
            uint256 eggId = allNestedEggs[nester][i];
            NestState storage nestState = nestStates[eggId];

            if (
                nestState.nestedTill != 0 &&
                block.number >= nestState.nestedTill
            ) {
                ++count;
            }
        }

        uint256 idx = 0;
        uint256[] memory eggIds = new uint256[](count);
        for (uint256 i = 0; i < allNestedEggs[nester].length; i++) {
            uint256 eggId = allNestedEggs[nester][i];
            NestState storage nestState = nestStates[eggId];

            if (
                nestState.nestedTill != 0 &&
                block.number >= nestState.nestedTill
            ) {
                eggIds[idx++] = eggId;
            }
        }

        return eggIds;
    }

    function hatch(uint256 eggId) public {
        NestState storage nestState = nestStates[eggId];

        require(nestState.rank == 0, "EGG_ALREADY_HATCHED");
        require(nestState.nestedTill != 0, "EGG_NOT_YET_NESTED");
        require(block.number >= nestState.nestedTill, "NESTING_INCOMPLETE");
        require(
            nestState.nestedBy == msg.sender || msg.sender == owner(),
            "NOT_THE_NESTER_OR_CONTRACT_OWNER"
        );

        // Generate a random number to determine whether the steal event occurs
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    randNonce,
                    block.coinbase,
                    block.prevrandao,
                    block.timestamp
                )
            )
        );
        randNonce += 1;

        uint256 hatchingRank = hatchingKomodoRank(nestState.nestedFor);

        // If the steal event occurs, choose a random komodo from the array of all komodo ids
        // weighted by the rank of each komodo
        bool stolen = randomNumber % 10000 <
            hatchingStealProbabilityBps(hatchingRank);

        address owner;
        if (stolen) {
            uint256 ownerId = komodoIdsRankWeighted[
                randomNumber % komodoIdsRankWeighted.length
            ];
            owner = roost.ownerOf(ownerId);

            nestStates[eggId] = NestState(0, 0, address(0), 0);
            emit EggStolen(eggId, nestState.nestedBy, owner, ownerId);
        } else {
            owner = msg.sender;

            nestState.rank = hatchingRank;
            nestState.nestedTill = 0;
            nestState.nestedFor = 0;

            for (uint256 i = 0; i < nestState.rank; i++) {
                komodoIdsRankWeighted.push(eggId);
            }

            emit EggHatched(eggId, nestState.nestedBy, nestState.rank);
            roost.emitMetadataUpdate(eggId);
        }

        roost.safeTransferFrom(address(this), owner, eggId);
    }

    function hatchAll(uint256[] calldata eggIds) public {
        for (uint256 i = 0; i < eggIds.length; i++) {
            hatch(eggIds[i]);
        }
    }

    function hatchingStealProbabilityBps(
        uint256 rank
    ) public pure returns (uint256) {
        require(
            rank >= MIN_KOMODO_RANK && rank <= MAX_KOMODO_RANK,
            "INVALID_RANK"
        );
        return 2667 - (167 * rank);
    }

    function hatchingKomodoRank(
        uint256 nestedBlocks
    ) public pure returns (uint256) {
        return (nestedBlocks + 132000) / 34800;
    }

    function calculateNestingBlocks(
        uint256 rank
    ) public pure returns (uint256) {
        require(
            rank >= MIN_KOMODO_RANK && rank <= MAX_KOMODO_RANK,
            "INVALID_RANK"
        );
        return (34800 * rank) - 132000;
    }
}
