// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

/*

██        ██                   ██        ██                           
██████    ██    ████     ████  ██    ██  ██████      ████      ████      ████      ██████
██    ██  ██  ██    ██ ██      ██  ██    ██    ██  ██    ██  ██    ██  ██    ██  ████    
██    ██  ██  ██    ██ ██      ████      ██    ██  ██    ██  ██    ██  ██    ██      ████
██████    ██    ████     ████  ██  ████  ██████      ████    ██    ██    ██████  ██████  
                                                                             ██          
                                                                           ██            
*/

/// Sale has not begun yet or ended already.
/// @param isAfter is after the sale.
error SaleNotRunning(bool isAfter);

/// Insufficient amount for the transaction.
/// Needed `required` but sent `amount`.
/// @param sent sent amount.
/// @param required minimum amount to send.
error InsufficientAmount(uint256 sent, uint256 required);

error ReachedMaxSaleSupply();
error InvalidProof();
error NotAllowedToMintMore();
error RewardsNotAllowedYet();
error AllRewardsMinted();
error AddressQuantitiesMismatch();
error BongNotOwned();
error SmokingNotAllowedYet();
error NotEnoughSmokableMaterialLeft();
error ProbablyBiggestMistakeOfYourLife();
error BongAlreadyBeingUsed();
error WithdrawFailed();

contract BlockBongs is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MEDIA_HASH =
        0x46423d36827b76551823c9314af639b413a6f416b4987b752cc29a1ac2498d3e;
    uint256 public constant COLLECTION_SIZE = 4200;
    uint256 public constant DIRT_STAGES = 5;

    uint256 public constant GREENLIST_TOTAL_MINT_LIMIT = 420;
    uint256 public constant GREENLIST_PUBLIC_PER_ADDRESS = 2;
    uint256 public constant GREENLIST_SALE_START_TIME = 1648850400; // April 2, 2022 12:00:00 AM GMT+02:00
    uint256 public constant GREENLIST_MINT_PRICE = 0.024 ether;

    uint256 public constant PUBLIC_SALE_PER_ADDRESS = 4;
    uint256 public constant PUBLIC_SALE_START_TIME = 1648909200; // April 2, 2022 4:20:00 PM GMT+02:00
    uint256 public constant PUBLIC_SALE_MINT_PRICE = 0.0420 ether;

    uint256 public constant FINAL_SUPPLY_ADDITIONAL_PER_ADDRESS = 4;
    uint256 public constant FINAL_SUPPLY_START_MINT_PRICE = 0.420 ether;
    uint256 public constant FINAL_SUPPLY_PRICE_DISCOUNT_STEP = 0.0042 ether;
    uint256 public constant FINAL_SUPPLY_END_MINT_PRICE = 0.042 ether;
    uint256 public constant FINAL_SUPPLY_STEP_N_BLOCKS = 420;
    uint256 public constant FINAL_SUPPLY_STEPS =
        (FINAL_SUPPLY_START_MINT_PRICE - FINAL_SUPPLY_END_MINT_PRICE) /
            FINAL_SUPPLY_PRICE_DISCOUNT_STEP;
    uint256 public constant FINAL_SUPPLY_THRESHOLD = 4200 - 420;

    uint256 private constant MINT_SALE_PHASES = 4;
    uint256 public constant REWARD_ALLOW_THRESHOLD = 420;

    uint256 public constant UNBOXING_TIME = 1650421200; // April 20 2022 04:20:00 pm GMT+14:00
    uint256 public constant INITIAL_SMOKABLE_AMOUNT = 420 ether;
    uint256 public constant SMOKING_SESSION_PRICE = 0.024 ether;

    struct MintStats {
        uint16 greenlistMinted;
        uint16 publicSaleMinted;
        uint16 finalSupplySaleMinted;
        uint16[] bongsMinted;
    }
    enum MintStatsIndex {
        GREENLIST,
        PUBLIC,
        FINAL,
        REWARDS,
        PHASES_BONGS_FROM
    }
    struct SmokeStats {
        uint256 lastSmokedBlockNumber;
        uint128 lastSmokedTimes;
        uint128 smokedTimes;
    }

    string private _baseTokenURI;
    string private _baseBoxedTokenURI;
    uint256 public finalSupplyStartBlockNumber;
    bytes32 public greenlistMerkleRoot;
    bytes32 public greenlistMerkleLeavesListCidHash;
    uint256 private _startTokenIdFrom = 66; // 42 team and peer pressure group + 24 promo bongs
    uint256 private _amountSmoked;
    bool public smokingAllowed;

    mapping(address => uint16[MINT_SALE_PHASES +
        PUBLIC_SALE_PER_ADDRESS +
        FINAL_SUPPLY_ADDITIONAL_PER_ADDRESS])
        private _mintStats;

    mapping(uint256 => SmokeStats) public smokeStats;

    event BongSmoked(
        uint256 indexed tokenId,
        address indexed smoker,
        uint256 smokedTimes
    );

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "contract is not allowed to mint");
        _;
    }

    constructor() ERC721A("blockbongs", "BBBIT") {}

    function _startTokenId() internal view override returns (uint256) {
        return _startTokenIdFrom;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setGreenlistMerkleTreeData(
        bytes32 merkleRoot,
        bytes32 merkleLeavesListCidHash
    ) external onlyOwner {
        greenlistMerkleRoot = merkleRoot;
        greenlistMerkleLeavesListCidHash = merkleLeavesListCidHash;
    }

    function greenlistMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        callerIsUser
    {
        if (
            block.timestamp < GREENLIST_SALE_START_TIME ||
            block.timestamp >= PUBLIC_SALE_START_TIME
        ) {
            revert SaleNotRunning(block.timestamp >= PUBLIC_SALE_START_TIME);
        }
        if (totalSupply() + quantity > GREENLIST_TOTAL_MINT_LIMIT) {
            revert ReachedMaxSaleSupply();
        }
        if (
            !MerkleProof.verify(
                proof,
                greenlistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert InvalidProof();
        }

        uint256 remainingQuantity = GREENLIST_PUBLIC_PER_ADDRESS -
            _mintStats[msg.sender][uint8(MintStatsIndex.GREENLIST)];

        if (remainingQuantity == 0) {
            revert NotAllowedToMintMore();
        }

        quantity = Math.min(quantity, remainingQuantity);
        _safeMint(msg.sender, quantity);
        _saveMintedBongs(
            uint8(MintStatsIndex.GREENLIST),
            _currentIndex - quantity,
            quantity
        );

        refundIfOver(GREENLIST_MINT_PRICE * quantity);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        if (
            (block.timestamp < PUBLIC_SALE_START_TIME &&
                totalSupply() < GREENLIST_TOTAL_MINT_LIMIT) ||
            finalSupplyStartBlockNumber != 0
        ) {
            revert SaleNotRunning(finalSupplyStartBlockNumber != 0);
        }

        uint256 startTokenId = _currentIndex;
        quantity = Math.min(quantity, FINAL_SUPPLY_THRESHOLD - startTokenId);

        if (
            _mintStats[msg.sender][uint8(MintStatsIndex.GREENLIST)] +
                _mintStats[msg.sender][uint8(MintStatsIndex.PUBLIC)] +
                quantity >
            PUBLIC_SALE_PER_ADDRESS
        ) {
            revert NotAllowedToMintMore();
        }
        if (startTokenId + quantity == FINAL_SUPPLY_THRESHOLD) {
            finalSupplyStartBlockNumber = block.number;
        }

        _safeMint(msg.sender, quantity);
        _saveMintedBongs(uint8(MintStatsIndex.PUBLIC), startTokenId, quantity);

        refundIfOver(PUBLIC_SALE_MINT_PRICE * quantity);
    }

    function getFinalSupplyMintPrice() public view returns (uint256) {
        if (
            finalSupplyStartBlockNumber == 0 || _currentIndex == COLLECTION_SIZE
        ) {
            return 0;
        }

        return
            FINAL_SUPPLY_START_MINT_PRICE -
            FINAL_SUPPLY_PRICE_DISCOUNT_STEP *
            Math.min(
                (block.number - finalSupplyStartBlockNumber) /
                    FINAL_SUPPLY_STEP_N_BLOCKS,
                FINAL_SUPPLY_STEPS
            );
    }

    function finalSupplySaleMint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        if (finalSupplyStartBlockNumber == 0) {
            revert SaleNotRunning(false);
        }
        if (_currentIndex + quantity > COLLECTION_SIZE) {
            revert ReachedMaxSaleSupply();
        }
        if (
            _mintStats[msg.sender][uint8(MintStatsIndex.FINAL)] + quantity >
            FINAL_SUPPLY_ADDITIONAL_PER_ADDRESS
        ) {
            revert NotAllowedToMintMore();
        }

        uint256 startTokenId = _currentIndex;
        _safeMint(msg.sender, quantity);
        _saveMintedBongs(uint8(MintStatsIndex.FINAL), startTokenId, quantity);

        refundIfOver(getFinalSupplyMintPrice() * quantity);
    }

    function _saveMintedBongs(
        uint8 phaseIndex,
        uint256 startTokenId,
        uint256 quantity
    ) internal {
        uint16[MINT_SALE_PHASES +
            PUBLIC_SALE_PER_ADDRESS +
            FINAL_SUPPLY_ADDITIONAL_PER_ADDRESS]
            memory minterMintStats = _mintStats[msg.sender];
        uint256 bongsMintedCount = _numberMinted(msg.sender) -
            minterMintStats[uint8(MintStatsIndex.REWARDS)];

        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;
            tokenId++
        ) {
            minterMintStats[
                uint8(MintStatsIndex.PHASES_BONGS_FROM) +
                    bongsMintedCount -
                    quantity +
                    tokenId -
                    startTokenId
            ] = uint16(tokenId);
        }
        minterMintStats[phaseIndex] += uint8(quantity);

        _mintStats[msg.sender] = minterMintStats;
    }

    function rewardMint(address[] memory addresses, uint8[] memory quantities)
        external
        onlyOwner
        callerIsUser
    {
        if (totalSupply() < REWARD_ALLOW_THRESHOLD) {
            revert RewardsNotAllowedYet();
        }
        if (_startTokenIdFrom == 0) {
            revert AllRewardsMinted();
        }
        uint256 addressesLength = addresses.length;
        if (addressesLength != quantities.length) {
            revert AddressQuantitiesMismatch();
        }

        uint256 originalCurrentIndex = _currentIndex;
        _currentIndex = _startTokenIdFrom;

        for (uint256 i = 0; i < addressesLength; i++) {
            if (_startTokenIdFrom < quantities[i]) {
                revert NotAllowedToMintMore();
            }

            _currentIndex -= quantities[i];
            _startTokenIdFrom -= quantities[i];

            _safeMint(addresses[i], quantities[i]);
            _mintStats[addresses[i]][
                uint8(MintStatsIndex.REWARDS)
            ] += quantities[i];

            _currentIndex -= quantities[i];
        }

        _currentIndex = originalCurrentIndex;
    }

    function mintStats(address minter) public view returns (MintStats memory) {
        uint16[MINT_SALE_PHASES +
            PUBLIC_SALE_PER_ADDRESS +
            FINAL_SUPPLY_ADDITIONAL_PER_ADDRESS]
            memory minterMintStats = _mintStats[minter];
        uint16[] memory bongsMinted = new uint16[](_numberMinted(minter));
        uint256 bongsMintedCount = _numberMinted(msg.sender) -
            minterMintStats[uint8(MintStatsIndex.REWARDS)];

        for (uint256 i = 0; i < bongsMintedCount; i++) {
            bongsMinted[i] = minterMintStats[
                uint8(MintStatsIndex.PHASES_BONGS_FROM) + i
            ];
        }

        return
            MintStats(
                minterMintStats[uint8(MintStatsIndex.GREENLIST)],
                minterMintStats[uint8(MintStatsIndex.PUBLIC)],
                minterMintStats[uint8(MintStatsIndex.FINAL)],
                bongsMinted
            );
    }

    function _getBongDirtStage(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        SmokeStats memory bongSmokeStats = smokeStats[tokenId];
        if (bongSmokeStats.lastSmokedBlockNumber != 0) {
            uint256 blocksSinceSmoke = block.number -
                bongSmokeStats.lastSmokedBlockNumber;
            if (blocksSinceSmoke < bongSmokeStats.lastSmokedTimes) {
                bongSmokeStats.smokedTimes -= uint128(
                    bongSmokeStats.lastSmokedTimes - blocksSinceSmoke
                );
            }
        }

        if (bongSmokeStats.smokedTimes < 1) {
            return 0;
        } else if (bongSmokeStats.smokedTimes < 3) {
            return 1;
        } else if (bongSmokeStats.smokedTimes < 7) {
            return 2;
        } else if (bongSmokeStats.smokedTimes < 15) {
            return 3;
        } else {
            return 4;
        }
    }

    function remainingSmokableAmount() public view returns (uint256) {
        return INITIAL_SMOKABLE_AMOUNT - _amountSmoked;
    }

    function smokeBong(uint256 tokenId, uint128 smokeTimes) public payable {
        if (ownerOf(tokenId) != msg.sender) {
            revert BongNotOwned();
        }
        if (!smokingAllowed) {
            if (owner() != msg.sender) {
                revert SmokingNotAllowedYet();
            } else {
                smokingAllowed = true;
            }
        }
        if (smokeTimes == 0) {
            revert ProbablyBiggestMistakeOfYourLife();
        }
        uint256 requiredSmokableAmount = smokeTimes * SMOKING_SESSION_PRICE;
        if (requiredSmokableAmount > remainingSmokableAmount()) {
            revert NotEnoughSmokableMaterialLeft();
        }
        SmokeStats memory bongSmokeStats = smokeStats[tokenId];
        if (
            block.number - bongSmokeStats.lastSmokedBlockNumber <
            bongSmokeStats.lastSmokedTimes
        ) {
            revert BongAlreadyBeingUsed();
        }

        bongSmokeStats.smokedTimes += smokeTimes;
        bongSmokeStats.lastSmokedTimes = smokeTimes;
        bongSmokeStats.lastSmokedBlockNumber = block.number;
        smokeStats[tokenId] = bongSmokeStats;
        _amountSmoked += requiredSmokableAmount;

        emit BongSmoked(tokenId, msg.sender, smokeTimes);

        refundIfOver(requiredSmokableAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory base = block.timestamp >= UNBOXING_TIME
            ? _baseURI()
            : _baseBoxedURI();
        string memory _tokenURI = string(
            block.timestamp >= UNBOXING_TIME
                ? abi.encodePacked(
                    tokenId.toString(),
                    "_",
                    _getBongDirtStage(tokenId).toString(),
                    ".json"
                )
                : abi.encodePacked(tokenId.toString(), ".json")
        );

        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setBaseBoxedURI(string calldata baseBoxedURI) external onlyOwner {
        _baseBoxedTokenURI = baseBoxedURI;
    }

    function _baseBoxedURI() internal view returns (string memory) {
        return _baseBoxedTokenURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256[] memory a = new uint256[](balanceOf(owner));
            uint256 end = _currentIndex;
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            for (uint256 i; i < end; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    a[tokenIdsIdx++] = i;
                }
            }
            return a;
        }
    }

    function refundIfOver(uint256 price) private {
        if (msg.value < price) {
            revert InsufficientAmount(msg.value, price);
        }
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }
}
